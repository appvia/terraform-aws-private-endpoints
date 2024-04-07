
data "aws_region" "current" {}

## Find the inbound resolver if required 
data "aws_route53_resolver_endpoint" "inbound" {
  count = !var.resolvers.inbound.create && var.resolvers.inbound.use_existing != "" ? 1 : 0

  filter {
    name   = "Name"
    values = [var.resolvers.inbound.use_existing]
  }
}

## Find the outbound resolver if required 
data "aws_route53_resolver_endpoint" "outbound" {
  count = !var.resolvers.outbound.create && var.resolvers.outbound.use_existing != "" ? 1 : 0

  filter {
    name   = "Name"
    values = [var.resolvers.outbound.use_existing]
  }
}

locals {
  ## The endpoints we are going to provision in this VPC 
  endpoints = {
    for x in var.endpoints : x.service => {
      policy              = x.policy,
      private_dns_enabled = !contains(["s3", "dynamodb"], x.service) ? true : false
      route_table_ids     = local.enable_vpc_creation ? module.vpc[0].private_route_table_ids : x.route_table_ids
      service             = x.service,
      service_type        = x.service_type,
      tags                = merge(var.tags, { "Name" : format("%s-endpoint", x.service) }),
    }
  }

  ## A of the domains to endpoint configuration 
  endpoints_rules = { for x in var.endpoints : format("%s.%s.amazonaws.com", x.service, local.region) => x }
}

## Provision the network is required 
module "vpc" {
  count   = local.enable_vpc_creation ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.1.3"

  availability_zones     = var.network.availability_zones
  enable_ipam            = var.network.enable_ipam
  enable_transit_gateway = true
  ipam_pool_id           = var.network.ipam_pool_id
  name                   = var.name
  private_subnet_netmask = var.network.private_netmask
  tags                   = var.tags
  transit_gateway_id     = var.network.transit_gateway_id
  vpc_cidr               = var.network.vpc_cidr
}

## Provision the VPC endpoints within the network 
module "endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.7.0"

  create_security_group      = true
  endpoints                  = local.endpoints
  security_group_description = "Security group for VPC endpoints"
  security_group_name_prefix = "${var.name}-default"
  security_group_tags        = var.tags
  subnet_ids                 = local.private_subnet_ids
  tags                       = var.tags
  vpc_id                     = local.vpc_id

  security_group_rules = {
    ingress_https = {
      description = "Allow HTTPS traffic from the VPC"
      cidr_blocks = ["10.0.0.0/8"]
    }
    egress_all = {
      description = "Allow all traffic to leave the VPC"
      cidr_blocks = ["10.0.0.0/8"]
      from_port   = 0
      to_port     = 443
      type        = "egress"
    }
  }
}

## Provision the resolver rules per service 
resource "aws_route53_resolver_rule" "endpoints" {
  for_each = local.endpoints_rules

  domain_name          = each.key
  name                 = format("%s-%s", var.name, each.value.service)
  rule_type            = "FORWARD"
  resolver_endpoint_id = local.outbound_resolver_id
  tags                 = merge(var.tags, { "Name" : format("resolver-rule-%s", each.value.service) })

  dynamic "target_ip" {
    for_each = local.inbound_resolver_ip_addresses

    content {
      ip   = target_ip.value
      port = 53
    }
  }
}

## Associate the rule with the endpoints vpc 
resource "aws_route53_resolver_rule_association" "association" {
  for_each = local.endpoints_rules

  resolver_rule_id = aws_route53_resolver_rule.endpoints[each.key].id
  vpc_id           = local.vpc_id
}

## Create the RAM share 
resource "aws_ram_resource_share" "endpoints" {
  for_each = local.endpoints_rules

  allow_external_principals = false
  name                      = format("%s-%s-endpoints", var.sharing.share_prefix, each.value.service)
  tags                      = merge(var.tags, { "Name" : format("%s-%s-endpoints", var.sharing.share_prefix, each.value.service) })
}

## Associate the resource with the RAM share 
resource "aws_ram_resource_association" "endpoints" {
  for_each = local.endpoints_rules

  resource_arn       = aws_route53_resolver_rule.endpoints[each.key].arn
  resource_share_arn = aws_ram_resource_share.endpoints[each.key].arn
}

## Share resource with the principals 
module "ram_share" {
  for_each = local.endpoints_rules
  source   = "./modules/ram_share"

  ram_principals         = var.sharing.principals
  ram_resource_share_arn = aws_ram_resource_share.endpoints[each.key].arn
  tags                   = var.tags
}

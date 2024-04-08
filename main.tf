
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
      description = "Allow all https traffic to the private endpoints"
      cidr_blocks = ["10.0.0.0/8"]
    }
    egress_all = {
      description = "Allow all https traffic to the private endpoints"
      cidr_blocks = ["10.0.0.0/8"]
      from_port   = 443
      to_port     = 443
      type        = "egress"
    }
  }
}

## Provision the security group for the dns resolvers 
# tfsec:ignore:aws-ec2-no-public-egress-sgr
module "dns_security_group" {
  count   = local.enable_dns_security_group ? 1 : 0
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2"

  name                = "dns-resolvers-${var.name}"
  description         = "Allow DNS traffic to the route53 resolvers"
  ingress_cidr_blocks = ["10.0.0.0/8"]
  ingress_rules       = ["dns-tcp", "dns-udp"]
  egress_rules        = ["dns-tcp", "dns-udp"]
  tags                = merge(var.tags, { "Name" : "dns-resolvers-${var.name}" })
  vpc_id              = module.vpc[0].vpc_id
}

## Provision an inbound resolver if required
resource "aws_route53_resolver_endpoint" "inbound" {
  count = local.enable_inbound_resolver ? 1 : 0

  name               = "inbound-${var.name}"
  direction          = "INBOUND"
  protocols          = var.resolvers.inbound.protocols
  security_group_ids = [module.dns_security_group[0].security_group_id]
  tags               = var.tags

  dynamic "ip_address" {
    for_each = local.inbound_resolver_addresses

    content {
      subnet_id = ip_address.key
      ip        = ip_address.value
    }
  }
}

## Provision an outbound resolver if required
resource "aws_route53_resolver_endpoint" "outbound" {
  count = local.enable_outbound_resolver ? 1 : 0

  name               = "outbound-${var.name}"
  direction          = "OUTBOUND"
  protocols          = var.resolvers.outbound.protocols
  security_group_ids = [module.dns_security_group[0].security_group_id]
  tags               = var.tags

  dynamic "ip_address" {
    for_each = local.outbound_resolver_addresses

    content {
      subnet_id = ip_address.key
      ip        = ip_address.value
    }
  }
}

## Provision the resolver rules per aws service 
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
      ip = target_ip.value
    }
  }

  depends_on = [
    module.endpoints
  ]
}

## Provision the AWS RAM share - so we can share the rules with other accounts
resource "aws_ram_resource_share" "endpoints" {
  for_each = local.endpoints_rules

  allow_external_principals = false
  name                      = format("%s-%s-endpoints", var.sharing.share_prefix, each.value.service)
  tags                      = merge(var.tags, { "Name" : format("%s-%s-endpoints", var.sharing.share_prefix, each.value.service) })
}

## Associate each of the resolver rules with the resource share
resource "aws_ram_resource_association" "endpoints" {
  for_each = local.endpoints_rules

  resource_arn       = aws_route53_resolver_rule.endpoints[each.key].arn
  resource_share_arn = aws_ram_resource_share.endpoints[each.key].arn
}

## Associate the ram shares with the principals
module "ram_share" {
  for_each = local.endpoints_rules
  source   = "./modules/ram_share"

  ram_principals         = var.sharing.principals
  ram_resource_share_arn = aws_ram_resource_share.endpoints[each.key].arn
  tags                   = var.tags
}

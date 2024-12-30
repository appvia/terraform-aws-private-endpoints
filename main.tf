
## Provision the network is required 
module "vpc" {
  count   = local.enable_vpc_creation ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.3.3"

  availability_zones                     = var.network.availability_zones
  enable_default_route_table_association = var.network.enable_default_route_table_association
  enable_default_route_table_propagation = var.network.enable_default_route_table_propagation
  enable_ipam                            = local.enable_ipam
  enable_transit_gateway                 = true
  ipam_pool_id                           = var.network.ipam_pool_id
  name                                   = var.name
  private_subnet_netmask                 = var.network.private_netmask
  tags                                   = var.tags
  transit_gateway_id                     = var.network.transit_gateway_id
  vpc_cidr                               = var.network.vpc_cidr
  vpc_netmask                            = var.network.vpc_netmask
}

## Provision the private endpoint within the network
resource "aws_vpc_endpoint" "this" {
  for_each = local.endpoints

  auto_accept         = try(each.value.auto_accept, null)
  ip_address_type     = try(each.value.ip_address_type, null)
  policy              = try(each.value.policy, null)
  private_dns_enabled = try(each.value.service_type, "Interface") == "Interface" ? try(each.value.private_dns_enabled, null) : null
  route_table_ids     = try(each.value.service_type, "Interface") == "Gateway" ? lookup(each.value, "route_table_ids", null) : null
  security_group_ids  = try(each.value.service_type, "Interface") == "Interface" ? length(distinct(concat(local.security_group_ids, lookup(each.value, "security_group_ids", [])))) > 0 ? distinct(concat(local.security_group_ids, lookup(each.value, "security_group_ids", []))) : null : null
  service_name        = try(each.value.service_endpoint, null)
  subnet_ids          = try(each.value.service_type, "Interface") == "Interface" ? distinct(concat(local.private_subnet_ids, lookup(each.value, "subnet_ids", []))) : null
  tags                = merge(var.tags, try(each.value.tags, {}))
  vpc_endpoint_type   = try(each.value.service_type, "Interface")
  vpc_id              = local.vpc_id

  dynamic "dns_options" {
    for_each = try([each.value.dns_options], [])

    content {
      dns_record_ip_type                             = try(dns_options.value.dns_options.dns_record_ip_type, null)
      private_dns_only_for_inbound_resolver_endpoint = try(dns_options.value.private_dns_only_for_inbound_resolver_endpoint, null)
    }
  }
}

## Provision the security group for the private endpoints 
resource "aws_security_group" "this" {
  description = "Security group for the private endpoints for the ${var.name} environment"
  name        = "${var.name}-default"
  tags        = merge(var.tags, { "Name" = "${var.name}-default" })
  vpc_id      = local.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

## Provision the security group rule to permit all internal traffic 
resource "aws_vpc_security_group_ingress_rule" "allow_https_ingress" {
  cidr_ipv4         = "10.0.0.0/8"
  description       = "Allow all https traffic to the private endpoint for the ${var.name} environment"
  from_port         = 443
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.this.id
  tags              = var.tags
  to_port           = 443
}

## Provision the security group rules to allow all https egress traffic 
resource "aws_vpc_security_group_egress_rule" "allow_https_egress" {
  cidr_ipv4         = "10.0.0.0/8"
  description       = "Allow all https traffic from the private endpoints for the ${var.name} environment"
  from_port         = 443
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.this.id
  tags              = var.tags
  to_port           = 443
}

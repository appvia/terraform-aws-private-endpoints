
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


## Provision the security group for the dns resolvers 
# tfsec:ignore:aws-ec2-no-public-egress-sgr
module "dns_security_group" {
  count   = local.enable_dns_security_group ? 1 : 0
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name                = "dns-resolvers-${var.name}"
  description         = "Allow DNS traffic to the route53 resolvers"
  ingress_cidr_blocks = ["10.0.0.0/8"]
  ingress_rules       = ["dns-tcp", "dns-udp"]
  egress_rules        = ["dns-tcp", "dns-udp"]
  tags                = merge(var.tags, { "Name" : "dns-resolvers-${var.name}" })
  vpc_id              = local.vpc_id
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
    for_each = local.private_subnet_ids

    content {
      subnet_id = ip_address.value
    }
  }

  depends_on = [
    module.vpc,
  ]
}

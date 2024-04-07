
## Provision a security group for the outbound resolvers
resource "aws_security_group" "dns_outbound" {
  count = local.enable_dns_security_group ? 1 : 0

  name        = "allow-dns-outbound-${var.name}"
  description = "Allow DNS traffics to the outbound resolvers"
  tags        = merge(var.tags, { "Name" = "allow-dns-outbound-${var.name}" })
  vpc_id      = module.vpc[0].vpc_id
}

## Provision the dns security group for the inbound resolvers
resource "aws_security_group" "dns_inbound" {
  count = local.enable_dns_security_group ? 1 : 0

  name        = "allow-dns-inbound-${var.name}"
  description = "Allow DNS traffics to the inbound resolvers"
  tags        = merge(var.tags, { "Name" = "allow-dns-inbound-${var.name}" })
  vpc_id      = module.vpc[0].vpc_id
}

## We only allow traffic from the outbound resolvers 
resource "aws_vpc_security_group_ingress_rule" "dns_inbound_tcp_53_ingress" {
  count = local.enable_dns_security_group ? 1 : 0

  description                  = "Allow all dns tcp traffic from the outbound resolvers"
  from_port                    = 0
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.dns_outbound[0].id
  security_group_id            = aws_security_group.dns_inbound[0].id
  to_port                      = 53
}

## We only allow traffic from the outbound resolvers on udp
resource "aws_vpc_security_group_ingress_rule" "dns_inbound_udp_53_ingress" {
  count = local.enable_dns_security_group ? 1 : 0

  description                  = "Allow all dns udp traffic from the outbound resolvers"
  from_port                    = 0
  ip_protocol                  = "udp"
  referenced_security_group_id = aws_security_group.dns_outbound[0].id
  security_group_id            = aws_security_group.dns_inbound[0].id
  to_port                      = 53
}

## Provision an ingress rule for the dns security group 
resource "aws_vpc_security_group_ingress_rule" "allow_dns_tcp_outbound" {
  count = local.enable_dns_security_group ? 1 : 0

  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all dns tcp traffic to the outbound resolvers"
  from_port         = 53
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.dns_outbound[0].id
  to_port           = 53
}

## Provision an ingress rule for the dns security group 
resource "aws_vpc_security_group_ingress_rule" "allow_dns_udp_outbound" {
  count = local.enable_dns_security_group ? 1 : 0

  description       = "Allow all dns udp traffic to the outbound resolvers"
  security_group_id = aws_security_group.dns_outbound[0].id
  cidr_ipv4         = "10.0.0.0/8"
  from_port         = 53
  ip_protocol       = "udp"
  to_port           = 53
}

## Allow all traffic from the outbound resolvers to the inbound resolvers 
resource "aws_vpc_security_group_egress_rule" "dns_outbound_all_tcp_egress" {
  count = local.enable_dns_security_group ? 1 : 0

  description                  = "Allow all dns tcp traffic from the outbound resolvers"
  from_port                    = 0
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.dns_inbound[0].id
  security_group_id            = aws_security_group.dns_outbound[0].id
  to_port                      = 0
}


## Provision an inbound resolver 
resource "aws_route53_resolver_endpoint" "inbound" {
  count = local.enable_inbound_resolver ? 1 : 0

  name               = "inbound-${var.name}"
  direction          = "INBOUND"
  protocols          = var.resolvers.inbound.protocols
  security_group_ids = [aws_security_group.dns_inbound[0].id]
  tags               = var.tags

  dynamic "ip_address" {
    for_each = local.inbound_resolver_addresses

    content {
      subnet_id = ip_address.key
      ip        = ip_address.value
    }
  }
}

## Provision an outbound resolver 
resource "aws_route53_resolver_endpoint" "outbound" {
  count = local.enable_outbound_resolver ? 1 : 0

  name               = "outbound-${var.name}"
  direction          = "OUTBOUND"
  protocols          = var.resolvers.outbound.protocols
  security_group_ids = [aws_security_group.dns_outbound[0].id]
  tags               = var.tags

  dynamic "ip_address" {
    for_each = local.outbound_resolver_addresses

    content {
      subnet_id = ip_address.key
      ip        = ip_address.value
    }
  }
}

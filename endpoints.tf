
locals {
  ## The endpoints we are going to provision in this VPC
  endpoints = {
    for x in var.endpoints : x.service => {
      hosted_zone         = format("%s.%s.amazonaws.com", x.service, var.region),
      iam_policy          = x.policy,
      private_dns_enabled = false
      route_table_ids     = local.enable_vpc_creation ? module.vpc[0].private_route_table_ids : x.route_table_ids
      service_endpoint    = format("com.amazonaws.%s.%s", var.region, x.service),
      service_type        = x.service_type,
      tags                = merge(var.tags, { "Name" : format("%s-endpoint", x.service) }),
    }
  }

  ## A of the domains to endpoint configuration
  endpoints_rules = { for x in var.endpoints : format("%s.%s.amazonaws.com", x.service, var.region) => x }
  ## The security group ids to use for the endpoints
  security_group_ids = [aws_security_group.this.id]
}

## Provision the private endpoint within the network
resource "aws_vpc_endpoint" "this" {
  for_each = local.endpoints

  auto_accept         = try(each.value.auto_accept, null)
  ip_address_type     = try(each.value.ip_address_type, null)
  policy              = try(each.value.iam_policy, null)
  private_dns_enabled = false
  route_table_ids     = try(each.value.service_type, "Interface") == "Gateway" ? lookup(each.value, "route_table_ids", null) : null
  security_group_ids  = try(each.value.service_type, "Interface") == "Interface" ? length(distinct(concat(local.security_group_ids, lookup(each.value, "security_group_ids", [])))) > 0 ? distinct(concat(local.security_group_ids, lookup(each.value, "security_group_ids", []))) : null : null
  service_name        = try(each.value.service_endpoint, null)
  subnet_ids          = try(each.value.service_type, "Interface") == "Interface" ? distinct(concat(local.private_subnet_ids, lookup(each.value, "subnet_ids", []))) : null
  tags                = merge(local.tags, try(each.value.tags, {}))
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
  tags        = merge(local.tags, { "Name" = "${var.name}-default" })
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
  tags              = local.tags
  to_port           = 443
}

## Provision the security group rules to allow all https egress traffic
resource "aws_vpc_security_group_egress_rule" "allow_https_egress" {
  cidr_ipv4         = "10.0.0.0/8"
  description       = "Allow all https traffic from the private endpoints for the ${var.name} environment"
  from_port         = 443
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.this.id
  tags              = local.tags
  to_port           = 443
}

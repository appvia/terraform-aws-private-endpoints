
## Provision the resolver rules per aws service, unless we are creating a single resolver rule
resource "aws_route53_resolver_rule" "endpoints" {
  for_each = var.resolvers.create_single_resolver_rule ? {} : local.endpoints_rules

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

  depends_on = [module.endpoints]
}

## Provision a single resolver rule for all endpoints 
resource "aws_route53_resolver_rule" "endpoints_single" {
  count = var.resolvers.create_single_resolver_rule ? 1 : 0

  domain_name          = "${local.region}.amazonaws.com"
  name                 = "${var.name}-resolver-rule-all"
  rule_type            = "FORWARD"
  resolver_endpoint_id = local.outbound_resolver_id
  tags                 = merge(var.tags, { "Name" : "${var.name}-resolver-rule-all" })

  dynamic "target_ip" {
    for_each = local.inbound_resolver_ip_addresses

    content {
      ip = target_ip.value
    }
  }

  depends_on = [module.endpoints]
}

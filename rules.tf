
## Provision the resolver rules per aws service, unless we are creating a single resolver rule
resource "aws_route53_resolver_rule" "endpoints" {
  for_each = var.resolvers.create_single_resolver_rule ? {} : local.endpoints_rules

  domain_name          = each.key
  name                 = format("%s-%s", var.name, each.value.service)
  rule_type            = "FORWARD"
  resolver_endpoint_id = local.outbound_resolver_id
  tags                 = merge(var.tags, { "Name" : format("resolver-rule-%s", each.value.service) })

  target_ip {
    ip = local.vpc_dns_resolver
  }

  depends_on = [module.endpoints, module.vpc, data.aws_region.current]
}

## Provision a single resolver rule for all endpoints 
resource "aws_route53_resolver_rule" "endpoints_single" {
  count = var.resolvers.create_single_resolver_rule ? 1 : 0

  domain_name          = "${local.region}.amazonaws.com"
  name                 = "${var.name}-resolver-rule-all"
  rule_type            = "FORWARD"
  resolver_endpoint_id = local.outbound_resolver_id
  tags                 = merge(var.tags, { "Name" : "${var.name}-resolver-rule-all" })

  target_ip {
    ip = local.vpc_dns_resolver
  }

  depends_on = [module.endpoints, module.vpc]
}


locals {
  ## Indicates if we should enable resolver rules
  enable_resolver_rules = local.enable_outbound_resolver && var.resolver_rules != null

  ## The ip addresses for the rule to forward to
  vpc_dns_resolver = local.enable_vpc_creation ? cidrhost(module.vpc[0].vpc_attributes.cidr_block, 2) : var.network.vpc_dns_resolver
}

## Provision the resolver rules per aws service, unless we are creating a single resolver rule
resource "aws_route53_resolver_rule" "endpoints" {
  for_each = local.enable_resolver_rules ? local.endpoints_rules : {}

  domain_name          = each.key
  name                 = format("%s-%s", var.name, each.value.service)
  rule_type            = "FORWARD"
  resolver_endpoint_id = local.outbound_resolver_id
  tags                 = merge(var.tags, { "Name" : format("resolver-rule-%s", each.value.service) })

  target_ip {
    ip = local.vpc_dns_resolver
  }

  depends_on = [module.vpc]
}

## Provision the AWS RAM share - so we can share the rules with other accounts
resource "aws_ram_resource_share" "endpoints" {
  for_each = local.enable_resolver_rules ? local.endpoints_rules : {}

  allow_external_principals = false
  name                      = format("%s-%s-endpoints", var.resolver_rules.share_prefix, each.value.service)
  tags                      = merge(var.tags, { "Name" : format("%s-%s-endpoints", var.resolver_rules.share_prefix, each.value.service) })
}

## Associate each of the resolver rules with the resource share
resource "aws_ram_resource_association" "endpoints" {
  for_each = local.enable_resolver_rules ? local.endpoints_rules : {}

  resource_arn       = aws_route53_resolver_rule.endpoints[each.key].arn
  resource_share_arn = aws_ram_resource_share.endpoints[each.key].arn
}

## Associate the ram shares with the principals
module "ram_share" {
  for_each = local.enable_resolver_rules ? local.endpoints_rules : {}
  source   = "./modules/ram_share"

  ram_principals         = var.resolver_rules.principals
  ram_resource_share_arn = aws_ram_resource_share.endpoints[each.key].arn
}

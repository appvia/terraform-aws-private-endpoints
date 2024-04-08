
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


locals {
  ## The tags to use for the resources
  tags = merge(var.tags, {})
  ## A list of all the private hosted zones ids
  private_hosted_zone_ids = [for k, v in local.endpoints : aws_route53_zone.this[k].zone_id]
  ## A map of the service name to hosted zone id
  private_hosted_zone_map = { for k, v in local.endpoints : v.hosted_zone => aws_route53_zone.this[k].zone_id }
}

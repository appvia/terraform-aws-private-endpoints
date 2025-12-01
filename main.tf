
locals {
  ## Indicates if we should create a new VPC for the endpoints
  enable_vpc_creation = var.network.vpc_id == ""
  ## The private subnets to create resolvers on (either the VPC we created or the list provided)
  private_subnet_ids = local.enable_vpc_creation ? module.vpc[0].private_subnet_ids : keys(var.network.private_subnet_cidr_by_id)
  ## The vpc id, which is either the one we created or the one provided
  vpc_id = local.enable_vpc_creation ? try(module.vpc[0].vpc_id, null) : try(var.network.vpc_id, "")
}

## Provision the network is required
module "vpc" {
  count   = local.enable_vpc_creation ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.6.14"

  availability_zones                     = var.network.availability_zones
  enable_default_route_table_association = var.network.enable_default_route_table_association
  enable_default_route_table_propagation = var.network.enable_default_route_table_propagation
  enable_dynamodb_endpoint               = var.network.enable_dynamodb_endpoint
  enable_route53_resolver_rules          = var.network.enable_route53_resolver_rules
  enable_s3_endpoint                     = var.network.enable_s3_endpoint
  ipam_pool_id                           = var.network.ipam_pool_id
  name                                   = var.name
  private_subnet_netmask                 = var.network.private_netmask
  tags                                   = local.tags
  transit_gateway_id                     = var.network.transit_gateway_id
  vpc_cidr                               = var.network.vpc_cidr
  vpc_netmask                            = var.network.vpc_netmask
}

## Provision an hosted zone for each of the private endpoints
resource "aws_route53_zone" "this" {
  for_each = local.endpoints

  comment = "Private hosted zone for the ${var.name} environment, service: ${each.value.hosted_zone}"
  name    = each.value.hosted_zone
  tags    = local.tags

  vpc {
    vpc_id = local.vpc_id
  }

  lifecycle {
    ignore_changes = [vpc]
  }
}

## Provision a alias record in the hosted zone for each of the private endpoints
resource "aws_route53_record" "this" {
  for_each = local.endpoints

  allow_overwrite = true
  name            = each.value.hosted_zone
  type            = "A"
  zone_id         = aws_route53_zone.this[each.key].zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_vpc_endpoint.this[each.key].dns_entry[0].dns_name
    zone_id                = aws_vpc_endpoint.this[each.key].dns_entry[0].hosted_zone_id
  }
}

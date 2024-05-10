
## Find the current AWS region 
data "aws_region" "current" {}

## Find the VPC by id, if required
data "aws_vpc" "current" {
  count = local.enable_vpc_creation ? 0 : 1

  id = var.network.vpc_id
}

## Find the outbound resolver if required 
data "aws_route53_resolver_endpoint" "outbound" {
  count = !var.resolvers.outbound.create && var.resolvers.outbound.use_existing != "" ? 1 : 0

  filter {
    name   = "Name"
    values = [var.resolvers.outbound.use_existing]
  }
}

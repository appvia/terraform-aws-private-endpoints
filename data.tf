
data "aws_region" "current" {}

## Find the outbound resolver if required 
data "aws_route53_resolver_endpoint" "outbound" {
  count = !var.resolvers.outbound.create && var.resolvers.outbound.use_existing != "" ? 1 : 0

  filter {
    name   = "Name"
    values = [var.resolvers.outbound.use_existing]
  }
}

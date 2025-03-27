
locals {
  ## Indicates if we should create a new VPC for the endpoints
  enable_vpc_creation = var.network.create
  ## Indicates if we should provision a outbound resolver
  enable_outbound_resolver = var.resolvers.outbound.create
  ## Indicates if we should provision a security group for dns
  enable_dns_security_group = local.enable_outbound_resolver

  ## The private subnets to create resolvers on (either the VPC we created or the list provided)
  private_subnet_ids = local.enable_vpc_creation ? module.vpc[0].private_subnet_ids : keys(var.network.private_subnet_cidr_by_id)

  ## The id of the outbound resolver to use when forwarding dns requests (either the on we created or the one provided)
  outbound_resolver_id = local.enable_outbound_resolver ? aws_route53_resolver_endpoint.outbound[0].id : data.aws_route53_resolver_endpoint.outbound[0].id
  ## We need to create a map of subnet id to ip address of the resolver
  outbound_resolver_addresses = local.enable_vpc_creation ? {
    for k, v in module.vpc[0].private_subnet_cidr_by_id : k => cidrhost(v, var.resolvers.outbound.ip_address_offset)
    } : {
    for k, v in var.network.private_subnet_cidr_by_id : k => cidrhost(v, var.resolvers.outbound.ip_address_offset)
  }
  ## The ip addresses which the outbound resolvers will be using
  outbound_resolver_ip_addresses = local.enable_outbound_resolver ? local.outbound_resolver_addresses : data.aws_route53_resolver_endpoint.outbound[0].ip_addresses

  ## The ip addresses for the vpc resolver, where the outbound resolver will forward requests to
  vpc_dns_resolver = var.network.create ? cidrhost(module.vpc[0].vpc_attributes.cidr_block, 2) : var.network.vpc_dns_resolver
  ## The vpc id, which is either the one we created or the one provided
  vpc_id = local.enable_vpc_creation ? module.vpc[0].vpc_id : var.network.vpc_id

  ## The endpoints we are going to provision in this VPC
  endpoints = {
    for x in var.endpoints : x.service => {
      policy              = x.policy,
      private_dns_enabled = !contains(["dynamodb", "s3"], x.service) ? true : false
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

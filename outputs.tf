
output "endpoints" {
  description = "The attributes of the endpoints we created"
  value       = module.endpoints.endpoints
}

output "inbound_resolver_endpoint_id" {
  description = "The id of the inbound resolver if we created one"
  value       = local.enable_inbound_resolver ? aws_route53_resolver_endpoint.inbound[0].id : local.inbound_resolver_id
}

output "outbound_resolver_endpoint_id" {
  description = "The id of the outbound resolver if we created one"
  value       = local.enable_outbound_resolver ? aws_route53_resolver_endpoint.outbound[0].id : local.outbound_resolver_id
}

output "resolver_security_group_id" {
  description = "The id of the security group we created for the endpoints if we created one"
  value       = local.enable_dns_security_group ? module.dns_security_group[0].security_group_id : null
}

output "outbound_resolver_ip_addresses" {
  description = "The ip addresses of the outbound resolver if we created one"
  value       = local.enable_outbound_resolver ? local.outbound_resolver_ip_addresses : null
}

output "inbound_resolver_ip_addresses" {
  description = "The ip addresses of the inbound resolver if we created one"
  value       = local.enable_inbound_resolver ? local.inbound_resolver_ip_addresses : null
}

output "private_subnet_attributes_by_az" {
  description = "The attributes of the private subnets"
  value       = local.enable_vpc_creation ? module.vpc[0].private_subnet_attributes_by_az : null
}

output "rt_attributes_by_type_by_az" {
  description = "The attributes of the route tables"
  value       = local.enable_vpc_creation ? module.vpc[0].rt_attributes_by_type_by_az : null
}

output "vpc_id" {
  description = "The id of the vpc we used to provision the endpoints"
  value       = local.vpc_id
}

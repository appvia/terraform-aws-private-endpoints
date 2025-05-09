
output "endpoints" {
  description = "Array containing the full resource object and attributes for all endpoints created"
  value       = aws_vpc_endpoint.this
}

output "hosted_zone" {
  description = "A full list of the private hosted zones created"
  value       = local.private_hosted_zone_ids
}

output "hosted_zone_map" {
  description = "A map of the private hosted zones created"
  value       = local.private_hosted_zone_map
}

output "outbound_resolver_endpoint_id" {
  description = "The id of the outbound resolver if we created one"
  value       = local.enable_outbound_resolver ? local.outbound_resolver_id : null
}

output "outbound_resolver_ip_addresses" {
  description = "The ip addresses of the outbound resolver if we created one"
  value       = local.enable_outbound_resolver ? local.outbound_resolver_ip_addresses : null
}

output "private_subnet_attributes_by_az" {
  description = "The attributes of the private subnets"
  value       = local.enable_vpc_creation ? module.vpc[0].private_subnet_attributes_by_az : null
}

output "resolver_security_group_id" {
  description = "The id of the security group we created for the endpoints if we created one"
  value       = local.enable_outbound_resolver ? module.dns_security_group[0].security_group_id : null
}

output "rt_attributes_by_type_by_az" {
  description = "The attributes of the route tables"
  value       = local.enable_vpc_creation ? module.vpc[0].rt_attributes_by_type_by_az : null
}

output "transit_gateway_attachment_id" {
  description = "The id of the transit gateway we used to provision the endpoints"
  value       = local.enable_vpc_creation ? module.vpc[0].transit_gateway_attachment_id : var.network.transit_gateway_id
}

output "vpc_attributes" {
  description = "The attributes of the vpc we created"
  value       = local.enable_vpc_creation ? module.vpc[0].vpc_attributes : null
}

output "vpc_id" {
  description = "The id of the vpc we used to provision the endpoints"
  value       = local.vpc_id
}


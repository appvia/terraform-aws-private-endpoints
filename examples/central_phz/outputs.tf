output "endpoints" {
  description = "Array containing the full resource object and attributes for all endpoints created"
  value       = module.endpoints
}

output "hosted_zone" {
  description = "A full list of the private hosted zones created"
  value       = module.endpoints.hosted_zone
}

output "hosted_zone_map" {
  description = "A map of the private hosted zones created"
  value       = module.endpoints.hosted_zone_map
}

output "hosted_zone_arns" {
  description = "A map of the private hosted zones created and their arns"
  value       = module.endpoints.hosted_zone_arns
}

output "outbound_resolver_endpoint_id" {
  description = "The id of the outbound resolver if we created one"
  value       = module.endpoints.outbound_resolver_endpoint_id
}

output "outbound_resolver_ip_addresses" {
  description = "The ip addresses of the outbound resolver if we created one"
  value       = module.endpoints.outbound_resolver_ip_addresses
}

output "private_subnet_attributes_by_az" {
  description = "The attributes of the private subnets"
  value       = module.endpoints.private_subnet_attributes_by_az
}

output "resolver_security_group_id" {
  description = "The id of the security group we created for the endpoints if we created one"
  value       = module.endpoints.resolver_security_group_id
}

output "rt_attributes_by_type_by_az" {
  description = "The attributes of the route tables"
  value       = module.endpoints.rt_attributes_by_type_by_az
}

output "transit_gateway_attachment_id" {
  description = "The id of the transit gateway we used to provision the endpoints"
  value       = module.endpoints.transit_gateway_attachment_id
}

output "vpc_attributes" {
  description = "The attributes of the vpc we created"
  value       = module.endpoints.vpc_attributes
}

output "vpc_id" {
  description = "The id of the vpc we used to provision the endpoints"
  value       = module.endpoints.vpc_id
}

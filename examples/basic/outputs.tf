
output "endpoints" {
  description = "The attributes of the endpoints we created"
  value       = module.endpoints.endpoints
}

output "outbound_resolver_endpoint_id" {
  description = "The id of the outbound resolver if we created one"
  value       = module.endpoints.outbound_resolver_endpoint_id
}

output "outbound_resolver_ip_addresses" {
  description = "The ip addresses of the outbound resolver if we created one"
  value       = module.endpoints.outbound_resolver_ip_addresses
}

output "vpc_attributes" {
  description = "The attributes of the vpc we created"
  value       = module.endpoints.vpc_attributes
}

output "vpc_id" {
  description = "The id of the vpc we used to provision the endpoints"
  value       = module.endpoints.vpc_id
}

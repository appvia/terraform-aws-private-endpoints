
output "endpoints" {
  description = "The attributes of the endpoints we created"
  value       = module.endpoints.endpoints
}

output "inbound_resolver_endpoint_id" {
  description = "The id of the inbound resolver if we created one"
  value       = module.endpoints.inbound_resolver_endpoint_id
}

output "outbound_resolver_endpoint_id" {
  description = "The id of the outbound resolver if we created one"
  value       = module.endpoints.outbound_resolver_endpoint_id
}

output "resolver_security_group_id" {
  description = "The id of the security group we created for the endpoints if we created one"
  value       = module.endpoints.resolver_security_group_id
}

output "outbound_resolver_ip_addresses" {
  description = "The ip addresses of the outbound resolver if we created one"
  value       = module.endpoints.outbound_resolver_ip_addresses
}

output "inbound_resolver_ip_addresses" {
  description = "The ip addresses of the inbound resolver if we created one"
  value       = module.endpoints.inbound_resolver_ip_addresses
}

output "vpc_id" {
  description = "The id of the vpc we used to provision the endpoints"
  value       = module.endpoints.vpc_id
}

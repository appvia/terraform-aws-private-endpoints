
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

output "outbound_resolver_security_group_id" {
  description = "The id of the security group we created for the endpoints if we created one"
  value       = local.enable_dns_security_group ? aws_security_group.dns_outbound[0].id : null
}

output "inbound_resolver_security_group_id" {
  description = "The id of the security group we created for the endpoints if we created one"
  value       = local.enable_dns_security_group ? aws_security_group.dns_inbound[0].id : null
}

output "outbound_resolver_ip_addresses" {
  description = "The ip addresses of the outbound resolver if we created one"
  value       = local.enable_outbound_resolver ? local.outbound_resolver_ip_addresses : null
}

output "inbound_resolver_ip_addresses" {
  description = "The ip addresses of the inbound resolver if we created one"
  value       = local.enable_inbound_resolver ? local.inbound_resolver_ip_addresses : null
}

output "vpc_id" {
  description = "The id of the vpc we used to provision the endpoints"
  value       = local.vpc_id
}

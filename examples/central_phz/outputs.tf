
output "endpoints" {
  description = "The attributes of the endpoints we created"
  value       = module.endpoints.endpoints
}

output "vpc_attributes" {
  description = "The attributes of the vpc we created"
  value       = module.endpoints.vpc_attributes
}

output "vpc_id" {
  description = "The id of the vpc we used to provision the endpoints"
  value       = module.endpoints.vpc_id
}

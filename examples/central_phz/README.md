<!-- BEGIN_TF_DOCS -->
## Providers

No providers.

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoints"></a> [endpoints](#output\_endpoints) | Array containing the full resource object and attributes for all endpoints created |
| <a name="output_hosted_zone"></a> [hosted\_zone](#output\_hosted\_zone) | A full list of the private hosted zones created |
| <a name="output_hosted_zone_arns"></a> [hosted\_zone\_arns](#output\_hosted\_zone\_arns) | A map of the private hosted zones created and their arns |
| <a name="output_hosted_zone_map"></a> [hosted\_zone\_map](#output\_hosted\_zone\_map) | A map of the private hosted zones created |
| <a name="output_outbound_resolver_endpoint_id"></a> [outbound\_resolver\_endpoint\_id](#output\_outbound\_resolver\_endpoint\_id) | The id of the outbound resolver if we created one |
| <a name="output_outbound_resolver_ip_addresses"></a> [outbound\_resolver\_ip\_addresses](#output\_outbound\_resolver\_ip\_addresses) | The ip addresses of the outbound resolver if we created one |
| <a name="output_private_subnet_attributes_by_az"></a> [private\_subnet\_attributes\_by\_az](#output\_private\_subnet\_attributes\_by\_az) | The attributes of the private subnets |
| <a name="output_resolver_security_group_id"></a> [resolver\_security\_group\_id](#output\_resolver\_security\_group\_id) | The id of the security group we created for the endpoints if we created one |
| <a name="output_rt_attributes_by_type_by_az"></a> [rt\_attributes\_by\_type\_by\_az](#output\_rt\_attributes\_by\_type\_by\_az) | The attributes of the route tables |
| <a name="output_transit_gateway_attachment_id"></a> [transit\_gateway\_attachment\_id](#output\_transit\_gateway\_attachment\_id) | The id of the transit gateway we used to provision the endpoints |
| <a name="output_vpc_attributes"></a> [vpc\_attributes](#output\_vpc\_attributes) | The attributes of the vpc we created |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The id of the vpc we used to provision the endpoints |
<!-- END_TF_DOCS -->
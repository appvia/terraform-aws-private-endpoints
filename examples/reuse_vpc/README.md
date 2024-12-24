<!-- BEGIN_TF_DOCS -->
## Providers

No providers.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ipam_pool_id"></a> [ipam\_pool\_id](#input\_ipam\_pool\_id) | The ID of the IPAM pool to use for the VPC | `string` | `null` | no |
| <a name="input_ram_principals"></a> [ram\_principals](#input\_ram\_principals) | A list of the ARNs of the principals to associate with the resource | `map(string)` | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | The region to create the VPC in | `string` | `"eu-west-2"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_transit_gateway_id"></a> [transit\_gateway\_id](#input\_transit\_gateway\_id) | The ID of the transit gateway to connect the VPC to | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoints"></a> [endpoints](#output\_endpoints) | The attributes of the endpoints we created |
| <a name="output_outbound_resolver_endpoint_id"></a> [outbound\_resolver\_endpoint\_id](#output\_outbound\_resolver\_endpoint\_id) | The id of the outbound resolver if we created one |
| <a name="output_vpc_attributes"></a> [vpc\_attributes](#output\_vpc\_attributes) | The attributes of the vpc we created |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The id of the vpc we used to provision the endpoints |
<!-- END_TF_DOCS -->
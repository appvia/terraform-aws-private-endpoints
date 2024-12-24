<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ram_resource_share_arn"></a> [ram\_resource\_share\_arn](#input\_ram\_resource\_share\_arn) | The ARN of the RAM share to associate with the resource | `string` | n/a | yes |
| <a name="input_ram_principals"></a> [ram\_principals](#input\_ram\_principals) | A list of the ARNs of the principals to associate with the resource | `list(string)` | `[]` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
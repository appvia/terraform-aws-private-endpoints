<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                     | Version   |
| ------------------------------------------------------------------------ | --------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.0.0  |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >= 5.0.0  |
| <a name="requirement_awscc"></a> [awscc](#requirement_awscc)             | >= 0.11.0 |

## Providers

No providers.

## Modules

| Name                                                           | Source | Version |
| -------------------------------------------------------------- | ------ | ------- |
| <a name="module_endpoints"></a> [endpoints](#module_endpoints) | ../..  | n/a     |

## Resources

No resources.

## Inputs

| Name                                                                                    | Description                           | Type          | Default | Required |
| --------------------------------------------------------------------------------------- | ------------------------------------- | ------------- | ------- | :------: |
| <a name="input_transit_gateway_id"></a> [transit_gateway_id](#input_transit_gateway_id) | The ID of the transit gateway         | `string`      | n/a     |   yes    |
| <a name="input_tags"></a> [tags](#input_tags)                                           | A map of tags to add to all resources | `map(string)` | `{}`    |    no    |

## Outputs

No outputs.

<!-- END_TF_DOCS -->


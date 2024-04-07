![Github Actions](../../actions/workflows/terraform.yml/badge.svg)

# Terraform AWS Private Endpoints

<p align="center">
  </br>
  <img src="docs/private-endpoints.png" alt="AWS Private Endpoints"/>
</p>

## Description

The following module provides a AWS recommended pattern for sharing private endpoint services across multiple VPCs, interconnected via a transit gateway. The intent is to retain as much of the traffic directed to AWS services, private and off the internet. Used in combination with the [terraform-aws-connectivity](https://github.com/appvia/terraform-aws-connectivity).

## AWS References

- [AWS PrivateLink](https://docs.aws.amazon.com/privatelink/latest/userguide/what-is-privatelink.html)
- [Shared Private Endpoints](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/privately-access-a-central-aws-service-endpoint-from-multiple-vpcs.html)

## Usage

```hcl
module "example" {
  source  = "appvia/<NAME>/aws"
  version = "0.0.1"

  # insert variables here
}
```

## Update Documentation

The `terraform-docs` utility is used to generate this README. Follow the below steps to update:

1. Make changes to the `.terraform-docs.yml` file
2. Fetch the `terraform-docs` binary (https://terraform-docs.io/user-guide/installation/)
3. Run `terraform-docs markdown table --output-file ${PWD}/README.md --output-mode inject .`

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_endpoints"></a> [endpoints](#module\_endpoints) | terraform-aws-modules/vpc/aws//modules/vpc-endpoints | 5.7.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | appvia/network/aws | 0.1.3 |

## Resources

| Name | Type |
|------|------|
| [aws_route53_resolver_endpoint.inbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_endpoint) | resource |
| [aws_route53_resolver_endpoint.outbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_endpoint) | resource |
| [aws_route53_resolver_rule.endpoints](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_rule) | resource |
| [aws_security_group.dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_ingress_rule.allow_dns_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.allow_dns_udp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_route53_resolver_endpoint.inbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_resolver_endpoint) | data source |
| [aws_route53_resolver_endpoint.outbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_resolver_endpoint) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_network"></a> [network](#input\_network) | The network to use for the inbound and outbound resolvers | <pre>object({<br>    # The number of availability zones to create subnets in<br>    availability_zones = optional(number, 2)<br>    # Whether to create the network<br>    create = optional(bool, false)<br>    # Whether to use ipam when creating the network<br>    enable_ipam = optional(bool, false)<br>    # The id of the ipam pool to use when creating the network<br>    ipam_pool_id = optional(string, null)<br>    # The subnet mask for private subnets, when creating the network<br>    private_netmask = optional(number, 24)<br>    # The ids of the private subnets to if we are reusing an existing network<br>    private_subnet_ids = optional(list(string), null)<br>    ## The transit gateway id to use for the network<br>    transit_gateway_id = optional(string, null)<br>    # The cider range to use for the VPC, when creating the network<br>    vpc_cidr = optional(string, null)<br>    # The vpc id to use when reusing an existing network <br>    vpc_id = optional(string, null)<br>  })</pre> | n/a | yes |
| <a name="input_resolvers"></a> [resolvers](#input\_resolvers) | The resolvers to provision | <pre>object({<br>    inbound = object({<br>      # Whether to create the resolver <br>      create = optional(bool, true)<br>      # If creating the inbound resolver, the address offset to use i.e if<br>      ip_address_offset = optional(number, 11)<br>      # The protocols to use for the resolver<br>      protocols = optional(list(string), ["Do53", "DoH"])<br>      # When not creating the resolver, this is the name of the resolver to use<br>      use_existing = optional(string, null)<br>    })<br>    outbound = object({<br>      # Whether to create the resolver<br>      create = optional(bool, true)<br>      # If creating the outbound resolver, the address offset to use i.e if 10.100.0.0/24, offset 10, ip address would be 10.100.0.10<br>      ip_address_offset = optional(number, 10)<br>      # The protocols to use for the resolver<br>      protocols = optional(list(string), ["Do53", "DoH"])<br>      # When not creating the resolver, this is the name of the resolver to use<br>      use_existing = optional(string, null)<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | The tags to apply to the resources | `map(string)` | n/a | yes |
| <a name="input_endpoints"></a> [endpoints](#input\_endpoints) | The endpoints to use for the inbound and outbound resolvers | <pre>map(object({<br>    # Whether to enable private dns<br>    private_dns_enabled = optional(bool, true)<br>    # The route table ids to use for the endpoint, assuming a gateway endpoint<br>    route_table_ids = optional(list(string), null)<br>    # The security group ids to use for the endpoint, else create on the fly<br>    security_group_ids = optional(list(string), null)<br>    # The AWS service we are creating a endpoint for<br>    service = string<br>  }))</pre> | <pre>{<br>  "ec2": {<br>    "service": "ec2"<br>  },<br>  "ec2messages": {<br>    "service": "ec2messages"<br>  },<br>  "kms": {<br>    "service": "kms"<br>  },<br>  "logs": {<br>    "service": "logs"<br>  },<br>  "s3": {<br>    "service": "s3"<br>  },<br>  "secretsmanager": {<br>    "service": "secretsmanager"<br>  },<br>  "ssm": {<br>    "service": "ssm"<br>  },<br>  "ssmmessages": {<br>    "service": "ssmmessages"<br>  }<br>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the environment | `string` | `"endpoints"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoints"></a> [endpoints](#output\_endpoints) | The attributes of the endpoints we created |
| <a name="output_inbound_resolver_endpoint_id"></a> [inbound\_resolver\_endpoint\_id](#output\_inbound\_resolver\_endpoint\_id) | The id of the inbound resolver if we created one |
| <a name="output_outbound_resolver_endpoint_id"></a> [outbound\_resolver\_endpoint\_id](#output\_outbound\_resolver\_endpoint\_id) | The id of the outbound resolver if we created one |
| <a name="output_resolver_security_group_id"></a> [resolver\_security\_group\_id](#output\_resolver\_security\_group\_id) | The id of the security group we created for the endpoints if we created one |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The id of the vpc we used to provision the endpoints |
<!-- END_TF_DOCS -->

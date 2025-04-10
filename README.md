<!-- markdownlint-disable -->

<a href="https://www.appvia.io/"><img src="https://github.com/appvia/terraform-aws-private-endpoints/blob/main/docs/banner.jpg?raw=true" alt="Appvia Banner"/></a><br/><p align="right"> <a href="https://registry.terraform.io/modules/appvia/private-endpoints/aws/latest"><img src="https://img.shields.io/static/v1?label=APPVIA&message=Terraform%20Registry&color=191970&style=for-the-badge" alt="Terraform Registry"/></a></a> <a href="https://github.com/appvia/terraform-aws-private-endpoints/releases/latest"><img src="https://img.shields.io/github/release/appvia/terraform-aws-private-endpoints.svg?style=for-the-badge&color=006400" alt="Latest Release"/></a> <a href="https://appvia-community.slack.com/join/shared_invite/zt-1s7i7xy85-T155drryqU56emm09ojMVA#/shared-invite/email"><img src="https://img.shields.io/badge/Slack-Join%20Community-purple?style=for-the-badge&logo=slack" alt="Slack Community"/></a> <a href="https://github.com/appvia/terraform-aws-private-endpoints/graphs/contributors"><img src="https://img.shields.io/github/contributors/appvia/terraform-aws-private-endpoints.svg?style=for-the-badge&color=FF8C00" alt="Contributors"/></a>

<!-- markdownlint-restore -->
<!--
  ***** CAUTION: DO NOT EDIT ABOVE THIS LINE ******
-->

![Github Actions](https://github.com/appvia/terraform-aws-private-endpoints/actions/workflows/terraform.yml/badge.svg)

# Terraform AWS Private Endpoints

<p align="center">
  </br>
  <img src="https://github.com/appvia/terraform-aws-private-endpoints/blob/main/docs/private-endpoints.png?raw=true" alt="AWS Private Endpoints"/>
</p>
<em>The diagram above is a high level representation of the module and the resources it creates; note in this design we DO NOT create an inbound resolver, as its not technically required</em>

## Description

Using a AWS recommended pattern for sharing private endpoint services across multiple VPCs, interconnected via a transit gateway. The intent is to retain as much of the traffic directed to AWS services, private and off the internet. Used in combination with the [terraform-aws-connectivity](https://github.com/appvia/terraform-aws-connectivity).

## How it works

- A shared vpc called `var.name` is created and attached to the transit gateway. Note, this module does not perform any actions on the transit gateway, it is assumed the correct settings to enable connectivity between the `var.name` vpc and the spokes is in place.
- Inside the shared vpc the private endpoints are created, one for each service defined in `var.endpoints`. The default security groups permits all https traffic from `10.0.0.0/8` to ingress.
- Optionally, depending on the configuration of the module, a outbound resolver is created. The outbound resolver is used to resolve the AWS services, against the default VPC resolver (VPC+2 ip)
- Route53 resolver rules are created for each of the shared private endpoints, allowing the consumer to pick and choose which endpoints they want to resolve to the shared vpc.
- The endpoints are shared using AWS RAM to the all the principals defined in the `var.sharing.principals` list e.g. a collection of organizational units.
- The spoke vpc's are responsible for associating the resolver rules with their vpc.
- These rules intercept the DNS queries and route them to the shared vpc resolvers, returning the private endpoint ip address located within them.
- Traffic from the spoke to the endpoints once resolved, is routed via the transit gateway.

## AWS References

- [AWS PrivateLink](https://docs.aws.amazon.com/privatelink/latest/userguide/what-is-privatelink.html)
- [Shared Private Endpoints](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/privately-access-a-central-aws-service-endpoint-from-multiple-vpcs.html)

## Usage

```hcl
## Provision the endpoints and resolvers
module "endpoints" {
  source = "../.."

  name = "endpoints"
  tags = var.tags
  endpoints = {
    "s3" = {
      service = "s3"
    },
    "ec2" = {
      service = "ec2"
    },
    "ec2messages" = {
      service = "ec2messages"
    },
    "ssm" = {
      service = "ssm"
    },
    "ssmmessages" = {
      service = "ssmmessages"
    },
    "logs" = {
      service = "logs"
    },
    "kms" = {
      service = "kms"
    },
    "secretsmanager" = {
      service = "secretsmanager"
    }
  }

  sharing = {
    principals = values(var.ram_principals)
  }

  resolvers = {
    outbound = {
      create            = true
      ip_address_offset = 12
    }
  }

  network = {
    # Name of the network to create
    name = "endpoints"
    # Number of availability zones to create subnets in
    private_netmask = 24
    # The transit gateway to connect
    transit_gateway_id = var.transit_gateway_id
    # The cider range to use for the VPC
    vpc_cidr = "10.20.0.0/21"
  }
}
```

## Reuse Existing Network

In order to reuse and existing network (vpc), we need to pass the vpc_id and the subnets ids where the outbound resolver will be provisioned (assuming you are not reusing an existing resolver as well).

```hcl
## Provision the endpoints and resolvers
module "endpoints" {
  source = "../.."

  name = "endpoints"
  tags = var.tags
  endpoints = {
    "ec2" = {
      service = "ec2"
    },
    "ec2messages" = {
      service = "ec2messages"
    },
    "ssm" = {
      service = "ssm"
    },
    "ssmmessages" = {
      service = "ssmmessages"
    },
  }

  sharing = {
    principals = values(var.ram_principals)
  }

  resolvers = {
    outbound = {
      create            = true
      ip_address_offset = 10
    }
  }

  network = {
    ## The vpc_cidr of the network we are reusing
    vpc_cidr = <VPC_CIDR>
    ## Reuse the network we created above
    vpc_id = <VPC_ID>
    ## Reuse the private subnets we created above i.e subnet-id => cidr
    private_subnet_cidrs_by_id = module.network.private_subnet_cidrs_by_id
    ## Do not create a new network
    create = false
  }
}
```

## Update Documentation

The `terraform-docs` utility is used to generate this README. Follow the below steps to update:

1. Make changes to the `.terraform-docs.yml` file
2. Fetch the `terraform-docs` binary (https://terraform-docs.io/user-guide/installation/)
3. Run `terraform-docs markdown table --output-file ${PWD}/README.md --output-mode inject .`

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | The name of the environment | `string` | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | The network to use for the endpoints and optinal resolvers | <pre>object({<br/>    availability_zones = optional(number, 2)<br/>    # Indicates if we should create a new network or reuse an existing one<br/>    enable_default_route_table_association = optional(bool, true)<br/>    # Whether to associate the default route table<br/>    enable_default_route_table_propagation = optional(bool, true)<br/>    # Whether to propagate the default route table<br/>    enable_dynamodb_endpoint = optional(bool, false)<br/>    # Whether to enable the dynamodb endpoint<br/>    enable_route53_resolver_rules = optional(bool, false)<br/>    # Whether to enable the route53 resolver rules<br/>    enable_s3_endpoint = optional(bool, false)<br/>    # Whether to enable the s3 endpoint<br/>    ipam_pool_id = optional(string, null)<br/>    # The id of the ipam pool to use when creating the network<br/>    private_netmask = optional(number, 24)<br/>    # The subnet mask for private subnets, when creating the network i.e subnet-id => 10.90.0.0/24<br/>    private_subnet_cidr_by_id = optional(map(string), {})<br/>    # The ids of the private subnets to if we are reusing an existing network<br/>    transit_gateway_id = optional(string, null)<br/>    ## The transit gateway id to use for the network<br/>    vpc_cidr = optional(string, "")<br/>    # The cidrws range to use for the VPC, when creating the network<br/>    vpc_dns_resolver = optional(string, null)<br/>    # The ip address to use for the vpc dns resolver<br/>    vpc_id = optional(string, "")<br/>    # The vpc id to use when reusing an existing network<br/>    vpc_netmask = optional(number, null)<br/>    # When using ipam this the netmask to use for the VPC<br/>  })</pre> | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to deploy the resources | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | The tags to apply to the resources | `map(string)` | n/a | yes |
| <a name="input_endpoints"></a> [endpoints](#input\_endpoints) | The private endpoints to provision within the shared vpc | <pre>map(object({<br/>    # The route table ids to use for the endpoint, assuming a gateway endpoint<br/>    route_table_ids = optional(list(string), null)<br/>    # service_type of the endpoint i.e. Gateway, Interface<br/>    service_type = optional(string, "Interface")<br/>    # The security group ids to use for the endpoint, else create on the fly<br/>    security_group_ids = optional(list(string), null)<br/>    # The AWS service we are creating a endpoint for<br/>    service = string<br/>    # The IAM policy associated to the endpoint<br/>    policy = optional(string, null)<br/>  }))</pre> | <pre>{<br/>  "ec2": {<br/>    "service": "ec2"<br/>  },<br/>  "ec2messages": {<br/>    "service": "ec2messages"<br/>  },<br/>  "ssm": {<br/>    "service": "ssm"<br/>  },<br/>  "ssmmessages": {<br/>    "service": "ssmmessages"<br/>  }<br/>}</pre> | no |
| <a name="input_resolver_rules"></a> [resolver\_rules](#input\_resolver\_rules) | The configuration for sharing the resolvers to other accounts | <pre>object({<br/>    principals = optional(list(string), [])<br/>    ## The principals to share the resolvers with<br/>    share_prefix = optional(string, "resolvers")<br/>    # The preifx to use for the shared resolvers<br/>  })</pre> | `{}` | no |
| <a name="input_resolvers"></a> [resolvers](#input\_resolvers) | The resolvers to provision | <pre>object({<br/>    outbound = object({<br/>      ip_address_offset = optional(number, 10)<br/>      # If creating the outbound resolver, the address offset to use i.e if 10.100.0.0/24, offset 10, ip address would be 10.100.0.10<br/>      protocols = optional(list(string), ["Do53", "DoH"])<br/>      # The protocols to use for the resolver<br/>      use_existing = optional(string, null)<br/>      # When not creating the resolver, this is the name of the resolver to use<br/>    })<br/>    # The configuration for the outbound resolver<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoints"></a> [endpoints](#output\_endpoints) | Array containing the full resource object and attributes for all endpoints created |
| <a name="output_hosted_zone"></a> [hosted\_zone](#output\_hosted\_zone) | A full list of the private hosted zones created |
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

```

```

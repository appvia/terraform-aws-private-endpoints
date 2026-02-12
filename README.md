<!-- markdownlint-disable -->

<a href="https://www.appvia.io/"><img src="https://github.com/appvia/terraform-aws-private-endpoints/blob/main/docs/banner.jpg?raw=true" alt="Appvia Banner"/></a><br/><p align="right"> <a href="https://registry.terraform.io/modules/appvia/private-endpoints/aws/latest"><img src="https://img.shields.io/static/v1?label=APPVIA&message=Terraform%20Registry&color=191970&style=for-the-badge" alt="Terraform Registry"/></a></a> <a href="https://github.com/appvia/terraform-aws-private-endpoints/releases/latest"><img src="https://img.shields.io/github/release/appvia/terraform-aws-private-endpoints.svg?style=for-the-badge&color=006400" alt="Latest Release"/></a> <a href="https://appvia-community.slack.com/join/shared_invite/zt-1s7i7xy85-T155drryqU56emm09ojMVA#/shared-invite/email"><img src="https://img.shields.io/badge/Slack-Join%20Community-purple?style=for-the-badge&logo=slack" alt="Slack Community"/></a> <a href="https://github.com/appvia/terraform-aws-private-endpoints/graphs/contributors"><img src="https://img.shields.io/github/contributors/appvia/terraform-aws-private-endpoints.svg?style=for-the-badge&color=FF8C00" alt="Contributors"/></a>

<!-- markdownlint-restore -->
<!--
  ***** CAUTION: DO NOT EDIT ABOVE THIS LINE ******
-->

![Github Actions](https://github.com/appvia/terraform-aws-private-endpoints/actions/workflows/terraform.yml/badge.svg)

# Terraform AWS Private Endpoints

## Introduction

In multi-account AWS environments, organizations face a critical challenge: maintaining private connectivity to AWS services across dozens or hundreds of VPCs while avoiding the cost and operational overhead of deploying duplicate VPC endpoints in every network. This module solves this problem by implementing a centralized VPC endpoint architecture using AWS PrivateLink, Transit Gateway, and Route 53 Resolver.

The core issue addressed is **VPC endpoint sprawl**—when each application VPC creates its own private endpoints to services like S3, EC2, KMS, and Secrets Manager, organizations face escalating costs (typically $7-10/endpoint/month × services × VPCs) and complex DNS management across segregated networks. This module centralizes private endpoint provisioning in a single shared VPC, enabling spoke VPCs to consume these endpoints via Transit Gateway routing and automated DNS resolution.

### Architecture Overview

The module orchestrates three key components working together:

1. **Shared Endpoint VPC**: Creates or reuses a VPC attached to your Transit Gateway where all VPC endpoints reside. Supports both Interface endpoints (ENI-based for most services) and Gateway endpoints (route-based for S3/DynamoDB)

2. **Route 53 Private Hosted Zones & Resolver Rules**: Automatically creates private hosted zones for each service (e.g., `ec2.us-east-1.amazonaws.com`) and resolver rules that spoke VPCs associate with to route DNS queries to the shared VPC resolver

3. **AWS Resource Access Manager (RAM) Sharing**: Distributes resolver rules to organizational units or specific accounts, allowing spoke VPCs to selectively adopt endpoint resolution without manual configuration

Traffic flow: Application in spoke VPC → DNS query intercepted by resolver rule → Resolved to shared VPC endpoint IP → Traffic routed via Transit Gateway → VPC endpoint forwards to AWS service.

### Cloud Context

This module is designed for AWS Organizations with Transit Gateway-based hub-and-spoke network architectures. It assumes:
- An existing Transit Gateway with proper routing configured between the shared VPC and spoke VPCs
- Organizational units or account structures for RAM sharing
- VPCs using the AWS-provided DNS resolver (VPC+2 address)

The module is particularly valuable in AWS Landing Zone environments, Control Tower setups, or any multi-account strategy where centralized infrastructure services reduce duplication.

## Features

### Security by Default

- **Private Network Isolation**: All AWS service traffic remains within the AWS private network—no internet traversal, reducing attack surface and compliance risk
- **Automated Security Groups**: Creates ingress/egress rules permitting HTTPS (port 443) from RFC1918 space (10.0.0.0/8 by default), with support for custom security groups per endpoint
- **IAM Policy Enforcement**: Optional IAM policies on VPC endpoints to restrict which principals can invoke API operations through the endpoint
- **Least-Privilege RAM Sharing**: Resolver rules shared only to specified organizational units or accounts, preventing unauthorized endpoint consumption

### Flexibility

- **Interface and Gateway Endpoint Support**: Handles both ENI-based Interface endpoints (most services) and route-table-based Gateway endpoints (S3, DynamoDB)
- **Bring Your Own Network**: Supports creating a new VPC or reusing existing VPC infrastructure by specifying `network.vpc_id` and subnet mappings
- **Selective Endpoint Provisioning**: Define exactly which AWS services need endpoints—deploy only EC2/SSM for management infrastructure or add KMS/Secrets Manager for application needs
- **Outbound Resolver Optional**: Choose whether to create an outbound Route 53 Resolver endpoint (required for DNS resolution from spokes) or reference an existing resolver
- **IPAM Integration**: Compatible with AWS IPAM for automated subnet allocation in dynamically scaled environments

### Operational Excellence

- **Multi-AZ High Availability**: VPC endpoints and resolvers automatically distributed across availability zones (configurable, default: 2 AZs)
- **Transit Gateway Auto-Attachment**: Automatically creates TGW attachment to the shared VPC with configurable route table association/propagation
- **Comprehensive Outputs**: Exports endpoint IDs, hosted zone IDs, resolver IPs, and RAM share ARNs for integration with downstream modules
- **Idempotent Resolver Rule Sharing**: Safely share resolver rules with additional OUs or accounts without disrupting existing associations
- **Lifecycle Management**: Proper Terraform dependency chains ensure ordered resource creation (VPC → endpoints → hosted zones → resolver rules → RAM shares)

### Compliance

- **PCI-DSS Alignment**: Supports requirement to keep cardholder data environments isolated from public internet by routing API calls through private endpoints
- **HIPAA Compliance**: Ensures PHI-related API calls (e.g., to S3 buckets with health data) never traverse public networks
- **AWS Well-Architected**: Implements Security Pillar best practices by encrypting data in transit and reducing public exposure
- **Audit-Ready DNS Logs**: Route 53 Resolver query logging can be enabled to track which workloads are accessing which services via private endpoints

## Usage Examples

### The "Golden Path" (Simple)

The most common deployment pattern—create a new shared VPC with standard endpoints, share across the organization:

```hcl
module "private_endpoints" {
  source  = "appvia/private-endpoints/aws"
  version = "~> 0.1"

  name   = "shared-endpoints"
  region = "us-east-1"
  
  tags = {
    Environment = "production"
    Owner       = "platform-team"
    ManagedBy   = "terraform"
  }

  # Standard AWS service endpoints for EC2 management
  endpoints = {
    ec2 = {
      service = "ec2"
    }
    ec2messages = {
      service = "ec2messages"
    }
    ssm = {
      service = "ssm"
    }
    ssmmessages = {
      service = "ssmmessages"
    }
    logs = {
      service = "logs"
    }
  }

  # Share resolver rules organization-wide
  sharing = {
    principals = [
      "arn:aws:organizations::123456789012:organization/o-abc123"
    ]
  }

  # Create outbound resolver for DNS resolution
  resolvers = {
    outbound = {
      create            = true
      ip_address_offset = 10
    }
  }

  # Create new VPC with Transit Gateway attachment
  network = {
    vpc_cidr           = "10.100.0.0/21"
    availability_zones = 3
    private_netmask    = 24
    transit_gateway_id = "tgw-abc123def456"
  }
}

# Spoke VPCs associate with the shared resolver rules
resource "aws_route53_resolver_rule_association" "spoke" {
  resolver_rule_id = module.private_endpoints.resolver_rules["ec2.us-east-1.amazonaws.com"]
  vpc_id           = "vpc-spoke123"
}
```

This configuration will:
- Create a new /21 VPC with 3 private subnets (/24 each)
- Deploy Interface endpoints for EC2, SSM, and CloudWatch Logs
- Create Route 53 private hosted zones and resolver rules
- Share resolver rules with the entire organization via RAM
- Attach the VPC to your Transit Gateway

**Cost**: ~$35-40/month ($7/endpoint × 5 services + minimal resolver costs)

### The "Power User" (Advanced)

Advanced configuration with custom security, IPAM integration, Gateway endpoints, and selective sharing:

```hcl
# Custom security group for KMS endpoint
resource "aws_security_group" "kms_endpoint" {
  name        = "kms-endpoint-custom"
  description = "Custom security group for KMS endpoint"
  vpc_id      = module.private_endpoints.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.50.0.0/16", "10.60.0.0/16"]  # Only specific spoke VPCs
    description = "HTTPS from approved spoke VPCs"
  }
}

module "private_endpoints" {
  source  = "appvia/private-endpoints/aws"
  version = "~> 0.1"

  name   = "prod-endpoints"
  region = "us-west-2"
  
  tags = {
    Environment        = "production"
    CostCenter         = "infrastructure"
    DataClassification = "confidential"
    ManagedBy          = "terraform"
  }

  endpoints = {
    # Gateway endpoints for S3 (no ENI charges)
    s3 = {
      service      = "s3"
      service_type = "Gateway"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Allow"
          Principal = "*"
          Action    = "s3:*"
          Resource  = "*"
          Condition = {
            StringEquals = {
              "aws:PrincipalOrgID" = "o-abc123"
            }
          }
        }]
      })
    }
    
    # Interface endpoint with custom security group
    kms = {
      service            = "kms"
      security_group_ids = [aws_security_group.kms_endpoint.id]
    }
    
    # Secrets Manager with IAM policy restrictions
    secretsmanager = {
      service = "secretsmanager"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Allow"
          Principal = "*"
          Action    = "secretsmanager:GetSecretValue"
          Resource  = "arn:aws:secretsmanager:us-west-2:*:secret:prod/*"
        }]
      })
    }
    
    # Standard endpoints
    ec2         = { service = "ec2" }
    ec2messages = { service = "ec2messages" }
    ssm         = { service = "ssm" }
    ssmmessages = { service = "ssmmessages" }
  }

  # Share only with production and security OUs
  sharing = {
    principals = [
      "arn:aws:organizations::123456789012:ou/o-abc123/ou-prod-xyz789",
      "arn:aws:organizations::123456789012:ou/o-abc123/ou-security-321abc"
    ]
  }

  # Share resolver rules separately to additional OUs
  resolver_rules = {
    principals = [
      "arn:aws:organizations::123456789012:ou/o-abc123/ou-staging-456def"
    ]
    share_prefix = "prod-resolver-rules"
  }

  resolvers = {
    outbound = {
      create            = true
      ip_address_offset = 12
      protocols         = ["Do53", "DoH"]  # Enable DNS-over-HTTPS
    }
  }

  # Use IPAM for dynamic IP allocation
  network = {
    ipam_pool_id       = "ipam-pool-0abc123def456"
    vpc_netmask        = 21
    availability_zones = 3
    private_netmask    = 24
    transit_gateway_id = "tgw-abc123def456"
    
    # Enable Transit Gateway route table association
    enable_default_route_table_association = true
    enable_default_route_table_propagation = true
  }
}

# Output resolver IPs for custom DNS forwarders
output "resolver_ips" {
  value       = module.private_endpoints.outbound_resolver_ip_addresses
  description = "Outbound resolver IPs for configuring on-premises DNS forwarders"
}
```

This advanced example demonstrates:
- Gateway endpoints for S3 to avoid ENI charges
- Custom security groups with restrictive CIDR ranges
- IAM policies on endpoints to limit API operations
- Separate resolver rule sharing to different OUs
- IPAM integration for automated CIDR allocation
- DNS-over-HTTPS protocol support
- Conditional IAM policies scoped to organization

### The "Migration" (Edge Case)

Importing existing VPC and resolver infrastructure into Terraform management:

```hcl
# Import existing VPC created outside Terraform
# terraform import 'module.private_endpoints.module.vpc[0].aws_vpc.this["shared-endpoints"]' vpc-existing123

# Use existing outbound resolver (created manually or by another stack)
data "aws_route53_resolver_endpoint" "existing" {
  filter {
    name   = "name"
    values = ["existing-outbound-resolver"]
  }
}

module "private_endpoints" {
  source  = "appvia/private-endpoints/aws"
  version = "~> 0.1"

  name   = "migrated-endpoints"
  region = "eu-west-1"
  
  tags = merge(
    var.common_tags,
    {
      MigratedFrom = "manual-cloudformation"
      MigrationDate = "2026-02-12"
    }
  )

  endpoints = {
    # Migrate to terraform management while preserving existing endpoints
    ec2 = { service = "ec2" }
    ssm = { service = "ssm" }
    kms = { service = "kms" }
  }

  sharing = {
    principals = var.organizational_units
  }

  # Reference existing outbound resolver instead of creating new
  resolvers = {
    outbound = {
      use_existing = data.aws_route53_resolver_endpoint.existing.name
    }
  }

  # Reuse existing VPC and subnets
  network = {
    vpc_id    = "vpc-existing123"
    vpc_cidr  = "10.80.0.0/21"
    
    # Map existing private subnets
    private_subnet_cidr_by_id = {
      "subnet-abc123" = "10.80.0.0/24"
      "subnet-def456" = "10.80.1.0/24"
      "subnet-ghi789" = "10.80.2.0/24"
    }
    
    # Skip VPC creation
    create = false
  }
}

# Import existing endpoints before applying
# terraform import 'module.private_endpoints.aws_vpc_endpoint.this["ec2"]' vpce-existing-ec2-123
# terraform import 'module.private_endpoints.aws_vpc_endpoint.this["ssm"]' vpce-existing-ssm-456
```

Migration workflow:
1. Import existing VPC: `terraform import 'module.private_endpoints.module.vpc[0].aws_vpc.this["name"]' vpc-xxx`
2. Import existing endpoints: `terraform import 'module.private_endpoints.aws_vpc_endpoint.this["service"]' vpce-xxx`
3. Set `network.create = false` and provide `vpc_id` and subnet mappings
4. Reference existing resolver via `resolvers.outbound.use_existing`
5. Run `terraform plan` to verify no changes to existing resources
6. Gradually add new endpoints through Terraform

## Operational Context

### Cost Implications

**VPC Endpoint Costs** (per region, per month):
- Interface Endpoints: ~$7.20/endpoint ($0.01/hour) + $0.01/GB data processed
- Gateway Endpoints: No charge for S3 and DynamoDB gateway endpoints

**Route 53 Resolver Costs**:
- Outbound Endpoint: ~$0.125/hour × 2 ENIs (for HA) = ~$180/year
- Resolver Queries: $0.40/million queries (typically negligible)

**Example Cost Breakdown**:
- 5 Interface endpoints (EC2, SSM, KMS, Secrets Manager, Logs): 5 × $7.20 = **$36/month**
- 1 Gateway endpoint (S3): **$0/month**
- Outbound resolver (2 AZs × 2 IPs): 4 × ~$0.125/hour × 730 hours = **$365/month**
- **Total**: ~$401/month shared across your entire organization

**Cost Savings**: If you have 50 VPCs, centralized endpoints save ~$18,000/month compared to deploying 5 endpoints in each VPC (50 × 5 × $7.20 = $1,800/month per-VPC approach × 50 VPCs).

**Optimization Tips**:
- Use Gateway endpoints (S3, DynamoDB) instead of Interface endpoints where possible—they're free
- Deploy endpoints only for services you actively use—don't default to "all services"
- Consider single-AZ deployment for non-production shared VPCs to halve resolver costs
- Use AWS Cost Explorer tags to track endpoint costs: tag with `Purpose=shared-endpoints`

### Known Limitations

- **DNS Propagation Delay**: Route 53 resolver rule associations can take 2-3 minutes to become active in spoke VPCs. Plan for this delay in automation pipelines

- **Transit Gateway Dependency**: This module does not configure Transit Gateway routing. You must ensure:
  - Spoke VPCs have routes to the shared VPC CIDR via TGW
  - Shared VPC has routes back to spoke VPCs (if using Interface endpoints)
  - TGW route tables have appropriate associations and propagations

- **Service Endpoint Regional Limits**: Interface endpoints consume ENIs in your VPC. Default limit is 350 ENIs per VPC. Each endpoint uses 1 ENI per AZ (e.g., 3 AZs = 3 ENIs per endpoint)

- **Private Hosted Zone Limits**: AWS limits you to 500 private hosted zones per account. Each endpoint creates one private hosted zone

- **DNS Resolution Scope**: Outbound resolvers only work for spoke VPCs using AWS-provided DNS (VPC+2). On-premises networks or VPCs with custom DNS servers need additional configuration

- **Gateway Endpoint Route Table Conflicts**: If you specify `route_table_ids` for Gateway endpoints (S3, DynamoDB), ensure those route tables don't have conflicting routes to the same CIDR ranges

- **RAM Sharing Limitations**: Resolver rules can be shared, but VPC endpoints themselves cannot be directly shared via RAM. Spokes access endpoints via DNS resolution, not direct sharing

### Breaking Changes

**v0.2.0 (Planned)**:
- `network.private_subnet_cidr_by_id` will be renamed to `network.private_subnet_cidrs_by_id` (plural) for consistency
- Minimum AWS provider version will increase to 5.0.0
- `sharing` variable will become optional with default `{principals = []}`

**v0.1.0 (Current)**:
- Initial release
- Requires AWS provider >= 5.0.0
- Creates private hosted zones with lifecycle `ignore_changes` on VPC associations

## Update Documentation

The `terraform-docs` utility is used to generate the tables below. Follow these steps to update:

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
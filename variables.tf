
variable "endpoints" {
  description = "The private endpoints to provision within the shared vpc"
  type = map(object({
    # The route table ids to use for the endpoint, assuming a gateway endpoint
    route_table_ids = optional(list(string), null)
    # service_type of the endpoint i.e. Gateway, Interface
    service_type = optional(string, "Interface")
    # The security group ids to use for the endpoint, else create on the fly
    security_group_ids = optional(list(string), null)
    # The AWS service we are creating a endpoint for
    service = string
    # The IAM policy associated to the endpoint
    policy = optional(string, null)
  }))
  default = {
    ec2 = {
      service = "ec2"
    },
    ec2messages = {
      service = "ec2messages"
    },
    ssm = {
      service = "ssm"
    },
    ssmmessages = {
      service = "ssmmessages"
    },
  }
}

variable "name" {
  description = "The name of the environment"
  type        = string
}

variable "network" {
  description = "The network to use for the endpoints and optinal resolvers"
  type = object({
    availability_zones = optional(number, 2)
    # Indicates if we should create a new network or reuse an existing one
    enable_default_route_table_association = optional(bool, true)
    # Whether to associate the default route table
    enable_default_route_table_propagation = optional(bool, true)
    # Whether to propagate the default route table
    enable_dynamodb_endpoint = optional(bool, false)
    # Whether to enable the dynamodb endpoint
    enable_route53_resolver_rules = optional(bool, false)
    # Whether to enable the route53 resolver rules
    enable_s3_endpoint = optional(bool, false)
    # Whether to enable the s3 endpoint
    ipam_pool_id = optional(string, null)
    # The id of the ipam pool to use when creating the network
    private_netmask = optional(number, 24)
    # The subnet mask for private subnets, when creating the network i.e subnet-id => 10.90.0.0/24
    private_subnet_cidr_by_id = optional(map(string), {})
    # The ids of the private subnets to if we are reusing an existing network
    transit_gateway_id = optional(string, null)
    ## The transit gateway id to use for the network
    vpc_cidr = optional(string, "")
    # The cidrws range to use for the VPC, when creating the network
    vpc_dns_resolver = optional(string, null)
    # The ip address to use for the vpc dns resolver
    vpc_id = optional(string, "")
    # The vpc id to use when reusing an existing network
    vpc_netmask = optional(number, null)
    # When using ipam this the netmask to use for the VPC
  })
}

variable "region" {
  description = "The region to deploy the resources"
  type        = string
}

variable "resolvers" {
  description = "The resolvers to provision"
  type = object({
    outbound = object({
      ip_address_offset = optional(number, 10)
      # If creating the outbound resolver, the address offset to use i.e if 10.100.0.0/24, offset 10, ip address would be 10.100.0.10
      protocols = optional(list(string), ["Do53", "DoH"])
      # The protocols to use for the resolver
      use_existing = optional(string, null)
      # When not creating the resolver, this is the name of the resolver to use
    })
    # The configuration for the outbound resolver
  })
  default = null
}

variable "resolver_rules" {
  description = "The configuration for sharing the resolvers to other accounts"
  type = object({
    principals = optional(list(string), [])
    ## The principals to share the resolvers with
    share_prefix = optional(string, "resolvers")
    # The preifx to use for the shared resolvers
  })
  default = {}
}

variable "tags" {
  description = "The tags to apply to the resources"
  type        = map(string)
}

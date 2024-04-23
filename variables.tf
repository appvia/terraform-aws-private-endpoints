
variable "resolvers" {
  description = "The resolvers to provision"
  type = object({
    # Indicates we create a single resolver rule, rather than one per service_type 
    create_single_resolver_rule = optional(bool, false)
    # The configuration for the outbound resolver
    outbound = object({
      # Whether to create the resolver
      create = optional(bool, true)
      # If creating the outbound resolver, the address offset to use i.e if 10.100.0.0/24, offset 10, ip address would be 10.100.0.10
      ip_address_offset = optional(number, 10)
      # The protocols to use for the resolver
      protocols = optional(list(string), ["Do53", "DoH"])
      # When not creating the resolver, this is the name of the resolver to use
      use_existing = optional(string, null)
    })
  })
}

variable "sharing" {
  description = "The configuration for sharing the resolvers to other accounts"
  type = object({
    ## The principals to share the resolvers with 
    principals = optional(list(string), null)
    # The preifx to use for the shared resolvers
    share_prefix = optional(string, "resolvers")
  })
  default = {
    principals = []
  }
}

variable "endpoints" {
  description = "The private endpoints to provision within the shared vpc"
  type = map(object({
    # Whether to enable private dns
    private_dns_enabled = optional(bool, true)
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
    logs = {
      service = "logs"
    },
    kms = {
      service = "kms"
    },
    secretsmanager = {
      service = "secretsmanager"
    },
    s3 = {
      service = "s3"
    },
  }
}

variable "name" {
  description = "The name of the environment"
  type        = string
  default     = "endpoints"
}

variable "network" {
  description = "The network to use for the endpoints and optinal resolvers"
  type = object({
    # The number of availability zones to create subnets in
    availability_zones = optional(number, 2)
    # Whether to create the network
    create = optional(bool, false)
    # Whether to use ipam when creating the network
    enable_ipam = optional(bool, false)
    # The id of the ipam pool to use when creating the network
    ipam_pool_id = optional(string, null)
    # The subnet mask for private subnets, when creating the network
    private_netmask = optional(number, 24)
    # The ids of the private subnets to if we are reusing an existing network
    private_subnet_cidrs = optional(map(string), {})
    ## The transit gateway id to use for the network
    transit_gateway_id = optional(string, "")
    # The cider range to use for the VPC, when creating the network
    vpc_cidr = optional(string, "")
    # The vpc id to use when reusing an existing network 
    vpc_id = optional(string, "")
  })
}

variable "tags" {
  description = "The tags to apply to the resources"
  type        = map(string)
}

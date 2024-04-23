#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module
#####################################################################################

## Create a client network to test the endpoints
module "spoke" {
  source  = "appvia/network/aws"
  version = "0.3.0"

  availability_zones                    = 3
  enable_ipam                           = true
  enable_route53_resolver_rules         = true
  enable_transit_gateway                = true
  enable_transit_gateway_appliance_mode = true
  ipam_pool_id                          = var.ipam_pool_id
  name                                  = "spoke-dns"
  private_subnet_netmask                = 24
  tags                                  = var.tags
  transit_gateway_id                    = var.transit_gateway_id
  vpc_netmask                           = 22
}

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
      ip_address_offset = 10
    }
  }

  network = {
    create = true
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

#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module
#####################################################################################

locals {
  ram_principals = {
    "Infrastructure" = "arn:aws:organizations::XXXXXXXXXX:ou/o-XXXXXXXXXX/ou-1tbg-XXXXXXXX"
    "Deployments"    = "arn:aws:organizations::XXXXXXXXXX:ou/o-XXXXXXXXXX/ou-1tbg-XXXXXXXX"
    "Workloads"      = "arn:aws:organizations::XXXXXXXXXX:ou/o-XXXXXXXXXX/ou-1tbg-XXXXXXXX"
  }
  transit_gateway_id = "tgw-04ad8f026be8b7eb6"
  tags = {
    "Environment" : "production"
  }
  region       = "eu-west-2"
  ipam_pool_id = "ipam-0a1b2c3d4e5f6g7h8"
}

## Create a client network to test the endpoints
module "spoke" {
  source  = "appvia/network/aws"
  version = "0.6.5"

  availability_zones                    = 3
  enable_route53_resolver_rules         = true
  enable_transit_gateway_appliance_mode = true
  ipam_pool_id                          = local.ipam_pool_id
  name                                  = "spoke-dns"
  private_subnet_netmask                = 24
  tags                                  = local.tags
  transit_gateway_id                    = local.transit_gateway_id
  vpc_netmask                           = 22
}

## Provision the endpoints and resolvers
module "endpoints" {
  source = "../.."

  name   = "endpoints"
  tags   = local.tags
  region = local.region

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

  resolver_rules = {
    principals = values(local.ram_principals)
  }

  resolvers = {
    outbound = {
      create            = true
      ip_address_offset = 10
    }
  }

  network = {
    # Name of the network to create
    name = "endpoints"
    # Number of availability zones to create subnets in
    private_netmask = 24
    # The transit gateway to connect
    transit_gateway_id = local.transit_gateway_id
    # The cider range to use for the VPC
    vpc_cidr = "10.20.0.0/21"
  }
}

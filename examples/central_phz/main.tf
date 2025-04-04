#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module
#####################################################################################

locals {
  tags = {
    "Environment" = "Test",
    "Terraform"   = "true",
    "Owner"       = "Engineering"
  }

  transit_gateway_id = "tgw-0c5994aa363b1e132"
}

## Provision the endpoints and resolvers
module "endpoints" {
  source = "../../"

  name   = "endpoints"
  tags   = local.tags
  region = "eu-west-2"

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

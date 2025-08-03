#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module
#####################################################################################

locals {
  ipam_pool_id       = "ipam-0a1b2c3d4e5f6g7h8"
  region             = "eu-west-2"
  transit_gateway_id = "tgw-04ad8f026be8b7eb6"

  ram_principals = {
    "Infrastructure" = "arn:aws:organizations::XXXXXXXXXX:ou/o-XXXXXXXXXX/ou-1tbg-XXXXXXXX"
    "Deployments"    = "arn:aws:organizations::XXXXXXXXXX:ou/o-XXXXXXXXXX/ou-1tbg-XXXXXXXX"
    "Workloads"      = "arn:aws:organizations::XXXXXXXXXX:ou/o-XXXXXXXXXX/ou-1tbg-XXXXXXXX"
  }

  tags = {
    "Environment" = "Production"
    "Product"     = "LandingZone"
    "Owner"       = "Engineering"
  }
}

## Create a network for the endpoints to reuse
module "network" {
  source  = "appvia/network/aws"
  version = "0.6.10"

  availability_zones                    = 3
  enable_route53_resolver_rules         = true
  enable_transit_gateway_appliance_mode = true
  ipam_pool_id                          = local.ipam_pool_id
  name                                  = "endpoints"
  private_subnet_netmask                = 24
  tags                                  = local.tags
  transit_gateway_id                    = local.transit_gateway_id
  vpc_netmask                           = 22
}

## Provision the endpoints and resolvers
module "endpoints" {
  source = "../.."

  name   = "endpoints"
  region = local.region
  tags   = local.tags

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
    ## Reuse the network we created above
    vpc_id = module.network.vpc_id
    ## Reuse the private subnets we created above
    private_subnet_cidr_by_id = module.network.private_subnet_cidr_by_id
    ## The transit_gateway_id to use for the network
    transit_gateway_id = local.transit_gateway_id
    # vpc dns resolver ip
    vpc_dns_resolver = "10.0.0.1"
  }

  depends_on = [module.network]
}

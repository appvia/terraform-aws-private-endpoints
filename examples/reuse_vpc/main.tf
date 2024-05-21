#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module
#####################################################################################

## Create a network for the endpoints to reuse 
module "network" {
  source  = "appvia/network/aws"
  version = "0.3.0"

  availability_zones                    = 3
  enable_ipam                           = true
  enable_route53_resolver_rules         = true
  enable_transit_gateway                = true
  enable_transit_gateway_appliance_mode = true
  ipam_pool_id                          = var.ipam_pool_id
  name                                  = "endpoints"
  private_subnet_netmask                = 24
  tags                                  = var.tags
  transit_gateway_id                    = var.transit_gateway_id
  vpc_netmask                           = 22
}

## Provision the endpoints and resolvers 
module "endpoints" {
  source = "../.."

  name   = "endpoints"
  region = var.region
  tags   = var.tags

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
    ## Reuse the network we created above 
    vpc_id = module.network.vpc_id
    ## Reuse the private subnets we created above 
    private_subnet_cidr_by_id = module.network.private_subnet_cidr_by_id
    ## The transit_gateway_id to use for the network 
    transit_gateway_id = var.transit_gateway_id
    ## Do not create a new network 
    create = false
  }

  depends_on = [module.network]
}

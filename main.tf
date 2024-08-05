
## Provision the network is required 
module "vpc" {
  count   = local.enable_vpc_creation ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.3.1"

  availability_zones                     = var.network.availability_zones
  enable_default_route_table_association = var.network.enable_default_route_table_association
  enable_default_route_table_propagation = var.network.enable_default_route_table_propagation
  enable_ipam                            = local.enable_ipam
  enable_transit_gateway                 = true
  ipam_pool_id                           = var.network.ipam_pool_id
  name                                   = var.name
  private_subnet_netmask                 = var.network.private_netmask
  tags                                   = var.tags
  transit_gateway_id                     = var.network.transit_gateway_id
  vpc_cidr                               = var.network.vpc_cidr
  vpc_netmask                            = var.network.vpc_netmask
}

## Provision the VPC endpoints within the network 
module "endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.12.0"

  create_security_group      = true
  endpoints                  = local.endpoints
  security_group_description = "Allow all https traffic to the private endpoints"
  security_group_name_prefix = "${var.name}-default"
  security_group_tags        = var.tags
  subnet_ids                 = local.private_subnet_ids
  tags                       = var.tags
  vpc_id                     = local.vpc_id

  security_group_rules = {
    ingress_https = {
      description = "Allow all https traffic to the private endpoints"
      cidr_blocks = ["10.0.0.0/8"]
    }
    egress_all = {
      description = "Allow all https traffic to the private endpoints"
      cidr_blocks = ["10.0.0.0/8"]
      from_port   = 443
      to_port     = 443
      type        = "egress"
    }
  }

  depends_on = [module.vpc]
}

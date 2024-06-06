mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = [
        "eu-west-1a",
        "eu-west-1b",
        "eu-west-1c"
      ]
    }
  }
}

run "basic" {
  command = plan

  variables {
    resolvers = {
      outbound = {
        create            = true
        ip_address_offset = 10
      }
    }
    name   = "spoke-dns"
    region = "eu-west-2"
    network = {
      name               = "endpoints"
      private_netmask    = 24
      transit_gateway_id = "tgw-123456acb123"
      vpc_cidr           = "10.20.0.0/21"
    }
    tags = {
      Environment = "dev"
    }
  }

}

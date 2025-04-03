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

run "validate_resolvers" {
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
      Environment = "Development"
      Owner       = "Engineering"
      Product     = "LandingZone"
    }
  }

  assert {
    condition     = module.vpc[0] != null
    error_message = "We expected a vpc to be created"
  }

  assert {
    condition     = aws_ram_resource_share.endpoints["ssm.eu-west-2.amazonaws.com"].name == "resolvers-ssm-endpoints"
    error_message = "We expected a resource share for the ssm service"
  }

  assert {
    condition     = aws_ram_resource_share.endpoints["ssmmessages.eu-west-2.amazonaws.com"].name == "resolvers-ssmmessages-endpoints"
    error_message = "We expected a resource share for the ssmessages service"
  }

  assert {
    condition     = aws_ram_resource_share.endpoints["ec2messages.eu-west-2.amazonaws.com"].name == "resolvers-ec2messages-endpoints"
    error_message = "We expected a resource share for the ec2messages service"
  }

  assert {
    condition     = aws_ram_resource_association.endpoints["ec2.eu-west-2.amazonaws.com"] != null
    error_message = "We expected a resource association for the ec2 service"
  }

  assert {
    condition     = aws_ram_resource_association.endpoints["ec2messages.eu-west-2.amazonaws.com"] != null
    error_message = "We expected a resource association for the ec2messages service"
  }

  assert {
    condition     = aws_ram_resource_association.endpoints["ssm.eu-west-2.amazonaws.com"] != null
    error_message = "We expected a resource association for the ssm service"
  }

  assert {
    condition     = aws_ram_resource_association.endpoints["ssmmessages.eu-west-2.amazonaws.com"] != null
    error_message = "We expected a resource association for the ssmessages service"
  }

  assert {
    condition     = aws_route53_resolver_endpoint.outbound[0].direction == "OUTBOUND"
    error_message = "We expected a outbound resolver endpoint"
  }

  assert {
    condition     = aws_route53_resolver_endpoint.outbound[0].name == "outbound-spoke-dns"
    error_message = "We expected a resolver endpoint with the name outbound-spoke-dns"
  }

  assert {
    condition     = contains(aws_route53_resolver_endpoint.outbound[0].protocols, "Do53")
    error_message = "We expected a resolver endpoint with the protocols Do53 and DoH"
  }

  assert {
    condition     = contains(aws_route53_resolver_endpoint.outbound[0].protocols, "DoH")
    error_message = "We expected a resolver endpoint with the protocols Do53 and DoH"
  }

  assert {
    condition     = aws_route53_resolver_rule.endpoints["ec2.eu-west-2.amazonaws.com"].domain_name == "ec2.eu-west-2.amazonaws.com"
    error_message = "We expected a resolver rule for the ec2 service"
  }

  assert {
    condition     = aws_route53_resolver_rule.endpoints["ec2.eu-west-2.amazonaws.com"].rule_type == "FORWARD"
    error_message = "We expected a forward resolver rule for the ec2 service"
  }

  assert {
    condition     = aws_route53_resolver_rule.endpoints["ec2messages.eu-west-2.amazonaws.com"].domain_name == "ec2messages.eu-west-2.amazonaws.com"
    error_message = "We expected a resolver rule for the ec2messages service"
  }

  assert {
    condition     = aws_route53_resolver_rule.endpoints["ec2messages.eu-west-2.amazonaws.com"].rule_type == "FORWARD"
    error_message = "We expected a forward resolver rule for the ec2messages service"
  }

  assert {
    condition     = aws_route53_resolver_rule.endpoints["ssm.eu-west-2.amazonaws.com"].domain_name == "ssm.eu-west-2.amazonaws.com"
    error_message = "We expected a resolver rule for the ssm service"
  }

  assert {
    condition     = aws_route53_resolver_rule.endpoints["ssm.eu-west-2.amazonaws.com"].rule_type == "FORWARD"
    error_message = "We expected a forward resolver rule for the ssm service"
  }

  assert {
    condition     = aws_security_group.this != null && aws_security_group.this.name == "spoke-dns-default"
    error_message = "We expected a security group for the endpoints"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.allow_https_ingress.cidr_ipv4 == "10.0.0.0/8"
    error_message = "We expected a security group ingress rule to allow all traffic"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.allow_https_ingress.from_port == 443 && aws_vpc_security_group_ingress_rule.allow_https_ingress.to_port == 443
    error_message = "We expected a security group ingress rule to allow port 443"
  }

  assert {
    condition     = aws_vpc_security_group_egress_rule.allow_https_egress.cidr_ipv4 == "10.0.0.0/8"
    error_message = "We expected a security group egress rule to allow all traffic"
  }

  assert {
    condition     = aws_vpc_security_group_egress_rule.allow_https_egress.from_port == 443 && aws_vpc_security_group_egress_rule.allow_https_egress.to_port == 443
    error_message = "We expected a security group egress rule to allow port 443"
  }
}

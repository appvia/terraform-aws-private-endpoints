## Description: used to validate the phz module

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

run "validate_phz" {
  command = plan

  variables {
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
    condition     = aws_route53_zone.this["ec2"].name == "ec2.eu-west-2.amazonaws.com"
    error_message = "We expected a private hosted zone for the ec2 service"
  }

  assert {
    condition     = aws_route53_record.this["ec2messages"].name == "ec2messages.eu-west-2.amazonaws.com"
    error_message = "We expected a private hosted zone for the ec2messages service"
  }

  assert {
    condition     = aws_route53_record.this["ssm"].name == "ssm.eu-west-2.amazonaws.com"
    error_message = "We expected a private hosted zone for the ssm service"
  }

  assert {
    condition     = aws_route53_record.this["ssmmessages"].name == "ssmmessages.eu-west-2.amazonaws.com"
    error_message = "We expected a private hosted zone for the ssmessages service"
  }

  assert {
    condition     = aws_route53_record.this["ec2"].name == "ec2.eu-west-2.amazonaws.com"
    error_message = "We expected a private hosted zone for the ec2 service"
  }

  assert {
    condition     = aws_route53_record.this["ec2"].name == "ec2.eu-west-2.amazonaws.com" && aws_route53_record.this["ec2"].type == "A"
    error_message = "We expected a dns record for the ec2 service"
  }

  assert {
    condition     = aws_route53_record.this["ec2"].alias != null
    error_message = "We expected a alias record for the ec2 service"
  }

  assert {
    condition     = aws_route53_record.this["ec2messages"].name == "ec2messages.eu-west-2.amazonaws.com" && aws_route53_record.this["ec2messages"].type == "A"
    error_message = "We expected a dns record for the ec2messages service"
  }

  assert {
    condition     = aws_route53_record.this["ec2messages"].alias != null
    error_message = "We expected a alias record for the ec2messages service"
  }

  assert {
    condition     = aws_route53_record.this["ssm"].name == "ssm.eu-west-2.amazonaws.com" && aws_route53_record.this["ssm"].type == "A"
    error_message = "We expected a dns record for the ssm service"
  }

  assert {
    condition     = aws_route53_record.this["ssm"].alias != null
    error_message = "We expected a alias record for the ssm service"
  }

  assert {
    condition     = aws_vpc_endpoint.this["ec2"].service_name == "com.amazonaws.eu-west-2.ec2"
    error_message = "We expected a vpc endpoint for the ec2 service"
  }

  assert {
    condition     = aws_vpc_endpoint.this["ec2messages"].service_name == "com.amazonaws.eu-west-2.ec2messages"
    error_message = "We expected a vpc endpoint for the ec2messages service"
  }

  assert {
    condition     = aws_vpc_endpoint.this["ssm"].service_name == "com.amazonaws.eu-west-2.ssm"
    error_message = "We expected a vpc endpoint for the ssm service"
  }

  assert {
    condition     = aws_vpc_endpoint.this["ssmmessages"].service_name == "com.amazonaws.eu-west-2.ssmmessages"
    error_message = "We expected a vpc endpoint for the ssmessages service"
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

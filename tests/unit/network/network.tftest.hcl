# mock_provider => no credentials, no network, no cost. Tests LOGIC, not the cloud.
mock_provider "aws" {}

variables {
  name       = "t"
  cidr_block = "10.0.0.0/16"
  azs        = ["us-east-1a", "us-east-1b"]
}

run "one_public_and_private_subnet_per_az" {
  command = plan
  assert {
    condition     = length(aws_subnet.public) == 2 && length(aws_subnet.private) == 2
    error_message = "Expected 2 public + 2 private subnets."
  }
}

run "subnets_never_overlap" {
  command = plan
  assert {
    condition     = length(distinct(concat([for s in aws_subnet.public : s.cidr_block], [for s in aws_subnet.private : s.cidr_block]))) == 4
    error_message = "Subnet CIDRs must be unique."
  }
}

run "no_nat_by_default_cost_safety" {
  command = plan
  assert {
    condition     = length(aws_nat_gateway.this) == 0 && length(aws_eip.nat) == 0
    error_message = "NAT must be opt-in (it costs money)."
  }
}

run "single_nat" {
  command = plan
  variables {
    enable_nat = true
  }
  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "single_nat_gateway=true must create exactly one NAT."
  }
}

run "one_nat_per_az_when_ha" {
  command = plan
  variables {
    enable_nat         = true
    single_nat_gateway = false
  }
  assert {
    condition     = length(aws_nat_gateway.this) == 2
    error_message = "HA mode must create one NAT per AZ."
  }
}

run "web_rules_are_cartesian_product" {
  command = plan
  variables {
    allowed_ingress_cidrs = ["203.0.113.0/24", "198.51.100.0/24"]
  }
  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.web) == 4
    error_message = "2 CIDRs x 2 ports = 4 rules."
  }
}

run "rejects_invalid_cidr" {
  command = plan
  variables {
    cidr_block = "not-a-cidr"
  }
  expect_failures = [var.cidr_block]
}

run "rejects_single_az" {
  command = plan
  variables {
    azs = ["us-east-1a"]
  }
  expect_failures = [var.azs]
}

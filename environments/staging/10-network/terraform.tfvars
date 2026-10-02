environment        = "staging"
vpc_cidr           = "10.20.0.0/16"
azs                = ["us-east-1a", "us-east-1b"]
enable_nat         = true   # COST: ~$32/mo per NAT gateway. Required for private nodes to pull images.
single_nat_gateway = true    # prod: one NAT per AZ (HA). staging: shared (cheaper).

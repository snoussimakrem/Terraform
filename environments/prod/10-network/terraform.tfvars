environment        = "prod"
vpc_cidr           = "10.30.0.0/16"
azs                = ["us-east-1a", "us-east-1b", "us-east-1c"]
enable_nat         = true   # COST: ~$32/mo per NAT gateway. Required for private nodes to pull images.
single_nat_gateway = false    # prod: one NAT per AZ (HA). staging: shared (cheaper).

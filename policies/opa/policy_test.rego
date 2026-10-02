package main

import rego.v1

# Run with: conftest verify --policy policies/opa
test_public_bucket_acl_denied if {
	count(deny) > 0 with input as {"resource_changes": [{
		"address": "aws_s3_bucket_acl.x", "type": "aws_s3_bucket_acl", "mode": "managed",
		"change": {"actions": ["create"], "after": {"acl": "public-read"}},
	}]}
}

test_ssh_open_to_world_denied if {
	count(deny) > 0 with input as {"resource_changes": [{
		"address": "aws_vpc_security_group_ingress_rule.ssh", "type": "aws_vpc_security_group_ingress_rule", "mode": "managed",
		"change": {"actions": ["create"], "after": {"cidr_ipv4": "0.0.0.0/0", "from_port": 22}},
	}]}
}

test_https_open_to_world_allowed if {
	count(deny) == 0 with input as {"resource_changes": [{
		"address": "aws_vpc_security_group_ingress_rule.https", "type": "aws_vpc_security_group_ingress_rule", "mode": "managed",
		"change": {"actions": ["create"], "after": {"cidr_ipv4": "0.0.0.0/0", "from_port": 443}},
	}]}
}

test_unencrypted_db_denied if {
	count(deny) > 0 with input as {"resource_changes": [{
		"address": "aws_db_instance.w", "type": "aws_db_instance", "mode": "managed",
		"change": {"actions": ["create"], "after": {"storage_encrypted": false, "identifier": "dp-dev", "tags": {"Project": "dp"}}},
	}]}
}

test_nat_creates_cost_warning if {
	count(warn) == 1 with input as {"resource_changes": [{
		"address": "aws_nat_gateway.n", "type": "aws_nat_gateway", "mode": "managed",
		"change": {"actions": ["create"], "after": {}},
	}]}
}

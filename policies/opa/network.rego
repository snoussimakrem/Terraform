package main

import rego.v1

allowed_public_ports := {80, 443}

# No world-open ingress except web ports.
deny contains msg if {
	some rc in managed("aws_vpc_security_group_ingress_rule")
	rc.change.after.cidr_ipv4 == "0.0.0.0/0"
	not rc.change.after.from_port in allowed_public_ports
	msg := sprintf("%s: 0.0.0.0/0 ingress on port %v is forbidden", [rc.address, rc.change.after.from_port])
}

# The EKS API must not be open to the world.
deny contains msg if {
	some rc in managed("aws_eks_cluster")
	some vpc in rc.change.after.vpc_config
	vpc.endpoint_public_access == true
	"0.0.0.0/0" in vpc.public_access_cidrs
	msg := sprintf("%s: public EKS endpoint open to 0.0.0.0/0", [rc.address])
}

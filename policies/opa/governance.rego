package main

import rego.v1

# Cost + ownership guardrails.
taggable := {"aws_vpc", "aws_s3_bucket", "aws_kms_key", "aws_eks_cluster", "aws_db_instance", "aws_secretsmanager_secret"}

deny contains msg if {
	some t in taggable
	some rc in managed(t)
	not rc.change.after.tags.Project
	not rc.change.after.tags_all
	msg := sprintf("%s: missing required tag 'Project'", [rc.address])
}

# Encryption at rest is mandatory for databases.
deny contains msg if {
	some rc in managed("aws_db_instance")
	rc.change.after.storage_encrypted != true
	msg := sprintf("%s: storage_encrypted must be true", [rc.address])
}

# Production databases must not be deletable by a stray apply.
deny contains msg if {
	some rc in managed("aws_db_instance")
	contains(rc.change.after.identifier, "prod")
	rc.change.after.deletion_protection != true
	msg := sprintf("%s: prod database needs deletion_protection", [rc.address])
}

# Warn (not block) on paid resources so reviewers notice them in the PR.
warn contains msg if {
	some t in {"aws_nat_gateway", "aws_eks_cluster", "aws_db_instance"}
	some rc in managed(t)
	"create" in rc.change.actions
	msg := sprintf("COST: %s (%s) will be created: check docs/cost.md", [rc.address, t])
}

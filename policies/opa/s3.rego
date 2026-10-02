package main

import rego.v1

# Rule 1: every bucket needs a public-access block, and each must block everything.
# Heuristic: the plan's bucket->PAB link is unknown until apply, so we compare counts.
deny contains msg if {
	count(managed("aws_s3_bucket")) > count(managed("aws_s3_bucket_public_access_block"))
	msg := sprintf("%d S3 buckets but only %d public_access_block resources", [count(managed("aws_s3_bucket")), count(managed("aws_s3_bucket_public_access_block"))])
}

deny contains msg if {
	some rc in managed("aws_s3_bucket_public_access_block")
	some attr in ["block_public_acls", "block_public_policy", "ignore_public_acls", "restrict_public_buckets"]
	rc.change.after[attr] != true
	msg := sprintf("%s: %s must be true", [rc.address, attr])
}

# Rule 2: no ACL that grants public access.
deny contains msg if {
	some rc in managed("aws_s3_bucket_acl")
	rc.change.after.acl in {"public-read", "public-read-write", "authenticated-read"}
	msg := sprintf("%s: public ACL '%s' is forbidden", [rc.address, rc.change.after.acl])
}

# Rule 3: encryption must be KMS, not just AES256 (project standard; state bucket included).
deny contains msg if {
	some rc in managed("aws_s3_bucket_server_side_encryption_configuration")
	some rule in rc.change.after.rule
	some d in rule.apply_server_side_encryption_by_default
	d.sse_algorithm != "aws:kms"
	msg := sprintf("%s: use aws:kms, found %s", [rc.address, d.sse_algorithm])
}

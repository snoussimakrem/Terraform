# Partial backend configuration: the values (bucket, key, endpoints) are injected at `init` time
# from ../backend-<mode>.hcl + a path-derived key (scripts/stack.sh). Backends cannot use variables.
terraform {
  backend "s3" {}
}

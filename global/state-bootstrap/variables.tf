variable "state_bucket_name" {
  description = "Globally-unique name in real AWS (e.g. dp-tfstate-<account-id>). LocalStack: any."
  type        = string
  default     = "tfstate-platform-local"
}

variable "create_zone" {
  description = "COST: a Route 53 hosted zone is ~$0.50/month. Off by default."
  type        = bool
  default     = false
}
variable "domain_name" {
  type    = string
  default = "example.com"
}

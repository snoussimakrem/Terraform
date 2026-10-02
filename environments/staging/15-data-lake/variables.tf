variable "force_destroy" {
  description = "dev only: allow destroying non-empty buckets."
  type        = bool
  default     = false
}
variable "secret_recovery_window_days" {
  type    = number
  default = 7
}

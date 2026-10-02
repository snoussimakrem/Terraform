policy "require-project-tag-and-kms" {
  source            = "./require-project-tag-and-kms.sentinel"
  enforcement_level = "hard-mandatory" # advisory | soft-mandatory (overridable) | hard-mandatory
}

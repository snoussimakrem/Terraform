# tflint --init  (downloads plugins)   |   tflint --recursive
plugin "terraform" {
  enabled = true
  preset  = "recommended"   # unused vars, missing types/descriptions, naming, deprecated syntax
}
plugin "aws" {
  enabled = true
  version = "0.38.0"        # VERIFY latest at github.com/terraform-linters/tflint-ruleset-aws
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

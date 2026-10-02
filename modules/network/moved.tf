# `moved` blocks record refactors so Terraform renames state instead of destroy+create.
# Example (history): resource was once `aws_subnet.private_subnets`, renamed to `aws_subnet.private`.
# A moved block whose `from` never existed is a harmless no-op, so it is safe to keep.
moved {
  from = aws_subnet.private_subnets
  to   = aws_subnet.private
}

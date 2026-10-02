# State surgery & refactoring lab

> Rule 1: **back up first.** `terraform state pull > backup-$(date +%s).tfstate`. The bucket is versioned too.
> Rule 2: prefer declarative tools (`moved`, `import`, `removed`) over imperative ones (`state mv/rm`): they are code-reviewed and appear in plans.

| Goal | Preferred | Imperative fallback |
|---|---|---|
| Rename a resource/module | `moved { from = …  to = … }` | `terraform state mv A B` |
| Adopt an existing resource | `import { to = …  id = … }` | `terraform import ADDR ID` |
| Stop managing but keep it alive | `removed { from = …  lifecycle { destroy = false } }` | `terraform state rm ADDR` |
| Force recreate one resource | `terraform apply -replace=ADDR` | `taint` (deprecated) |
| Move between states (split a stack) | `state mv -state-out=…` or import+removed | |

## Lab 1: rename safely (moved)
1. `make apply ENV=dev STACK=10-network`
2. Rename `aws_security_group.web` → `aws_security_group.edge` in `modules/network/main.tf`; update references.
3. `terraform plan`: **without** a `moved` block you'll see destroy+create. Add:
   ```hcl
   moved { from = aws_security_group.web  to = aws_security_group.edge }
   ```
   Plan now says "has moved", 0 to destroy.
4. Question: why must you keep the `moved` block until every environment has applied?

## Lab 2: adopt (import)
Create a bucket by hand in LocalStack:
`aws --endpoint-url=http://localhost:4566 s3 mb s3://hand-made`
Then add `import { to = aws_s3_bucket.adopted  id = "hand-made" }` and `terraform plan -generate-config-out=generated.tf`.

## Lab 3: split a stack (state mv across states)
Move the NACL out of `10-network` into a new stack without destroying it: `state mv -state-out`, then add matching config.
Verify both plans are empty.

## Lab 4: break and recover
1. `terraform state rm 'module.network.aws_vpc.this'` (don't apply anything!)
2. `terraform plan` → wants to create a *second* VPC: Terraform forgot the first.
3. Recover with an `import` block or `terraform state push` of the backup. Explain what would have happened on apply.

## Lab 5: drift
Delete a subnet with the AWS CLI against LocalStack; `terraform plan` shows it will be recreated. Then change a tag by hand; observe `~` in-place update. Decide per the runbook which side is right.

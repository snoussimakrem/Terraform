# Runbook

Format: **Symptom → Diagnose → Fix → Prevent**. Commands are explained, not just listed.

## 0. First five minutes of any incident
1. **Stop the bleeding**: pause the pipeline (disable `terraform-apply` workflow). Concurrent applies make things worse.
2. `terraform plan` on the affected stack: *read-only*; shows what Terraform believes differs.
3. Check who/what changed last: `git log -5 -- environments/<env>/<stack>` and CloudTrail (real AWS).
4. Debug logs only when needed: `TF_LOG=debug TF_LOG_PATH=tf.log terraform plan` (the log can contain secrets, never attach it publicly).

## State lock: "Error acquiring the state lock"
- **Diagnose**: the message includes lock ID + who/when. Is that run still alive (check Actions)?
- **Fix**: wait. If the holder is dead: `terraform force-unlock <LOCK_ID>`. With S3 native locking this deletes the `<key>.tflock` object. **Only** after confirming nobody is applying.
- **Prevent**: workflow `concurrency` groups with `cancel-in-progress: false`.

## State recovery (corrupt / deleted / bad write)
The state bucket is versioned.
```bash
aws s3api list-object-versions --bucket <bucket> --prefix prod/20-cluster.tfstate
aws s3api get-object --bucket <bucket> --key prod/20-cluster.tfstate --version-id <GOOD_ID> restored.tfstate
terraform state push restored.tfstate     # refuses if lineage differs or serial is older; read the message
terraform plan                            # confirm: should be clean/expected
```
Serial/lineage safeguard: `terraform state push` rejects a state with older `serial` unless `-force`. That protects against overwriting newer state with an older copy.
If **no** state backup exists: rebuild with `import` blocks (see `state-surgery.md`).

## Drift
- **Detect**: nightly `drift-detection` workflow opens an issue (exit code 2).
- **Diagnose**: `terraform plan` shows `~` changes to resources nobody edited in code. Decide: *is the real-world change right?*
  - Real world is right → update the code to match, `plan` must become empty.
  - Code is right → `terraform apply` reconciles the cloud back.
  - Attribute is legitimately managed elsewhere (autoscaler) → `lifecycle { ignore_changes = [...] }` with a comment.
- **Prevent**: restrict console write access; tag `ManagedBy=terraform`.

## Helm release stuck / failed
- Symptom: `context deadline exceeded`, release `pending-install`.
- `helm -n <ns> list -a`, `kubectl -n <ns> get pods,events --sort-by=.lastTimestamp`, `kubectl -n <ns> describe pod <p>`.
- Usual causes: not enough RAM (OOMKilled/Pending), quota exceeded (`kubectl describe quota -n <ns>`), image pull, **NetworkPolicy blocking** (check `cilium` / `kubectl get netpol -n <ns>`).
- Fix: correct cause; `helm -n <ns> uninstall <rel>` if stuck in pending; `terraform apply` again. `atomic=true` rolls back on failure so usually no manual cleanup.

## Pods can't resolve DNS / reach a peer
Almost always a NetworkPolicy. Namespaces with `isolate = true` get default-deny; allowed paths are in `modules/kubernetes`. Add the peer to `peers`, don't remove the deny.

## Plan wants to REPLACE something important (`-/+`)
Stop. Read which argument forces it (`# forces replacement`). Options: revert the change; use `moved` if it was a rename; for data stores take a snapshot first; use `create_before_destroy` where possible.

## Accidentally destroyed / removed from state
- Removed from **state** only (`state rm`): resource still exists → `import` it back.
- Destroyed in the **cloud**: `terraform apply` recreates it. Data is gone unless versioned/snapshotted (S3 versioning, RDS snapshots).

## CI/CD rollback
Infrastructure rollback = **revert the commit** and let the pipeline apply the reverse change (PR → plan → approval → apply). Not `git reset` on main. Not hand-editing state. Caveats: destroys are not undoable; some changes (KMS key deletion, DB engine upgrades) are one-way: that is why prod needs approvals and deletion windows.

## Cost surprise
`make down` (local). Real AWS: `terraform destroy` per stack in **reverse** order (40 → 30 → 20 → 15 → 10), check Billing → Cost Explorer filtered by tag `Project`. Delete unattached EIPs/EBS volumes: they bill silently.

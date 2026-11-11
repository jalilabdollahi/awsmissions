# Solution

Three independent faults sit on the three hops of the function.

1. **Role identity policy lacks `s3:GetObject`.** `indexer-runtime` allowed list, write and DynamoDB, but not reading. Add `s3:GetObject` scoped to `arn:aws:s3:::hv-manifests/incoming/*` (not `*`, and not the payroll bucket) with `aws iam put-role-policy`.
2. **Bucket policy `FreezeOldIndexer` denies `s3:PutObject` on `processed/*` for the role.** An explicit Deny beats any Allow, so editing the role will never fix this. Fetch the bucket policy, delete only that statement, and put it back. The `ContractorsNotRestricted` statement is a real legal control and has to stay.
3. **The function's `MANIFEST_BUCKET` is `hv-manifest`.** Update the environment to `hv-manifests`.

`check` assumes the role as `hv-oncall` to probe each hop, makes sure the role cannot read payroll or overwrite `incoming/`, confirms the contractor is still blocked, and finally invokes the function and looks for the row in `hv-manifest-index`.

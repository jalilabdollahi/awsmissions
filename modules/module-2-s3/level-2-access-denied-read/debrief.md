# Debrief: a bucket policy grant must match principal, action and resource exactly

A resource-based policy grants access only if *all three* parts match the request: who (`Principal`), what (`Action`) and which object (`Resource`). A typo in any one produces the same flat `AccessDenied`, with no hint about which part is wrong.

**What happened here**
- The principal ARN named a user that does not exist (`dana-auditor`). IAM does not validate principals strictly in every system, so the policy was stored happily and simply never matched anybody.
- The `Resource` pointed at `report/*`. Object ARNs are plain string matches on the key, so `reports/q3.txt` does not match `report/*`.

**How S3 decides (same account)**
Access is granted if an identity policy *or* a bucket policy allows it and nothing denies it. That is why Dana, who has no IAM permissions, could work at all: the bucket policy was the only grant. If Dana lived in another account, both sides would have to allow.

**In real life**
- Use `aws iam get-user --user-name X` to copy the ARN instead of typing it. Real S3 rejects principals that do not resolve to an existing identity when you save the policy, but typos that resolve to *another* user will not warn you.
- Reach for `"Principal": "*"` only for truly public data. Read-only audit access should name the exact principal.
- Remember that `s3:GetObject` applies to objects (`bucket/key`), while `s3:ListBucket` applies to the bucket ARN. Dana can download, not browse, until you add a list grant on the bucket ARN.

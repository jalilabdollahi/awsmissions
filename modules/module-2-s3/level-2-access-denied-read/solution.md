# Solution

The bucket policy has two mistakes that each break the grant on their own:

- the `Principal` is `user/dana-auditor`, but the IAM user is `auditor-dana`;
- the `Resource` ends in `report/*` (singular), while the objects live under `reports/`.

1. Read what is attached now:

```bash
aws s3api get-bucket-policy --bucket meridian-audit-reports --query Policy --output text
```

2. Edit `bucket-policy.json` (`edit`) so the statement reads:

```json
"Principal": { "AWS": "arn:aws:iam::000000000000:user/auditor-dana" },
"Action": "s3:GetObject",
"Resource": "arn:aws:s3:::meridian-audit-reports/reports/*"
```

3. Apply it:

```bash
aws s3api put-bucket-policy --bucket meridian-audit-reports --policy file://bucket-policy.json
```

The validator downloads as `auditor-dana`, tries payroll, tries writing, and tries a second user. A public principal (`"*"`) or a wider Resource would fail those probes.

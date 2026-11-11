# Solution

`arn:aws:s3:::vantage-*/*` matches objects in **every** bucket whose name starts with `vantage-`: assets, renders, but also `vantage-payroll-exports` and `vantage-legal-hold`. It also covers any bucket created in the future with that prefix. Both read and write are granted everywhere.

1. See what the pattern reaches:

```bash
aws s3api list-buckets --query 'Buckets[].Name'
aws iam get-user-policy --user-name vantage-render --policy-name render-storage
```

2. Replace the wildcard with explicit ARNs, and give each action only to the buckets that need it, in `policy.json` (`edit`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {"Effect": "Allow", "Action": "s3:GetObject",
     "Resource": ["arn:aws:s3:::vantage-assets/*", "arn:aws:s3:::vantage-assets-eu/*"]},
    {"Effect": "Allow", "Action": "s3:PutObject",
     "Resource": "arn:aws:s3:::vantage-renders/*"}
  ]
}
```

3. Apply it:

```bash
aws iam put-user-policy --user-name vantage-render --policy-name render-storage --policy-document file://policy.json
```

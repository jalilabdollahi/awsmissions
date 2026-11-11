# Solution

An inline policy on an IAM **user** may be at most 2,048 characters in total (whitespace is not counted by AWS). The generated draft spells out 28 statements and is well over that, so `put-user-policy` fails with `LimitExceeded`. Managed policies have a larger limit (6,144 characters), and you can also make the policy much shorter.

Option A, keep the draft and use a managed policy:

```bash
aws iam create-policy --policy-name fleet-telemetry-read --policy-document file://policy.json
aws iam attach-user-policy --user-name fleet-ops --policy-arn arn:aws:iam::000000000000:policy/fleet-telemetry-read
```

Option B, consolidate in `policy.json` and attach it inline. Two statements are enough:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {"Effect": "Allow", "Action": "s3:ListBucket", "Resource": "arn:aws:s3:::fleet-*-telemetry"},
    {"Effect": "Allow", "Action": "s3:GetObject",  "Resource": "arn:aws:s3:::fleet-*-telemetry/*"}
  ]
}
```

The pattern `fleet-*-telemetry` matches only buckets that end in `-telemetry`, so `fleet-payroll` stays out. A looser pattern such as `fleet-*` would expose it. `check` reads from all 14 buckets and tests the payroll bucket.

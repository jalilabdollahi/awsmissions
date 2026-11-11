# Solution

The user `proofreader` has no IAM policy, so everything depends on the bucket policy. That policy has two mistakes: the Principal names `proof-reader` (with a hyphen) instead of `proofreader`, and the single statement mixes `s3:ListBucket` and `s3:GetObject` on the *bucket* ARN, while `GetObject` applies to objects (`.../*`).

1. Read the policy and the real user ARN:

```bash
aws s3api get-bucket-policy --bucket harborprint-proofs --query Policy --output text
aws iam get-user --user-name proofreader --query User.Arn
```

2. Rewrite `bucket-policy.json` (`edit`) with the correct principal and one statement per resource type:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {"Effect": "Allow", "Principal": {"AWS": "arn:aws:iam::000000000000:user/proofreader"},
     "Action": "s3:ListBucket", "Resource": "arn:aws:s3:::harborprint-proofs"},
    {"Effect": "Allow", "Principal": {"AWS": "arn:aws:iam::000000000000:user/proofreader"},
     "Action": "s3:GetObject", "Resource": "arn:aws:s3:::harborprint-proofs/proofs/*"}
  ]
}
```

3. Apply it:

```bash
aws s3api put-bucket-policy --bucket harborprint-proofs --policy file://bucket-policy.json
```

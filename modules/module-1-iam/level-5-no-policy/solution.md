# Solution

A Lambda function does not have permissions of its own: every AWS call it makes is signed with the credentials of its execution role. `invoice-digest-role` can be assumed by Lambda (that is the trust policy), but has no permissions policy, so every call is denied.

1. Find out what the function needs: list and read `bluefin-invoices`, write to `bluefin-digests`.
2. Fill in `policy.json` (`edit`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {"Effect": "Allow", "Action": "s3:ListBucket", "Resource": "arn:aws:s3:::bluefin-invoices"},
    {"Effect": "Allow", "Action": "s3:GetObject",  "Resource": "arn:aws:s3:::bluefin-invoices/*"},
    {"Effect": "Allow", "Action": "s3:PutObject",  "Resource": "arn:aws:s3:::bluefin-digests/*"}
  ]
}
```

3. Attach it to the role as an inline policy:

```bash
aws iam put-role-policy --role-name invoice-digest-role --policy-name digest-s3-access --policy-document file://policy.json
```

4. `check` invokes the function for real.

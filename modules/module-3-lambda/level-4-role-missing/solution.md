# Solution

The function's configuration names a role that was deleted. You need to recreate a role with the right trust and a minimal permissions policy, then point the function at it.

1. Confirm the dangling reference:

```bash
aws lambda get-function-configuration --function-name claim-receipt-archiver --query Role
aws iam get-role --role-name claim-archiver-role     # NoSuchEntity
```

2. Fill in the two workspace files (`edit trust-policy.json`, `edit permissions.json`):
   - trust policy: `"Principal": {"Service": "lambda.amazonaws.com"}`
   - permissions: `s3:PutObject` on `arn:aws:s3:::tidewater-claim-receipts/receipts/*` (the function only ever writes under `receipts/`)

3. Create the role, attach the permissions and switch the function over:

```bash
aws iam create-role --role-name claim-archiver-role \
  --assume-role-policy-document file://trust-policy.json
aws iam put-role-policy --role-name claim-archiver-role \
  --policy-name archive-receipts --policy-document file://permissions.json
aws lambda update-function-configuration --function-name claim-receipt-archiver \
  --role arn:aws:iam::000000000000:role/claim-archiver-role
```

The checker invokes the function: archiving must succeed, and the `bucket` override pointed at `tidewater-claim-evidence` must be refused.

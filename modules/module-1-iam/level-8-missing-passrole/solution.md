# Solution

Attaching an execution role to a Lambda function is a separate permission: `iam:PassRole` on that role. The pipeline has `lambda:CreateFunction`, but nothing that lets it *hand* `promo-fn-role` to anything.

1. Add a statement to `policy.json` (`edit`):

```json
{
  "Sid": "HandOverPromoRole",
  "Effect": "Allow",
  "Action": "iam:PassRole",
  "Resource": "arn:aws:iam::000000000000:role/promo-fn-role",
  "Condition": {"StringEquals": {"iam:PassedToService": "lambda.amazonaws.com"}}
}
```

2. Apply it:

```bash
aws iam put-user-policy --user-name kestrel-releaser --policy-name release-pipeline --policy-document file://policy.json
```

The Resource must be the specific role. With `"Resource": "*"` the pipeline could pass `platform-admin-role` too, which would let it run code as an administrator. `check` verifies both directions.

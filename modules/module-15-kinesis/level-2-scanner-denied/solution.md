# Solution

Two things in the copied policy are wrong for production:

- the **action** is `kinesis:PutRecord`, but the gateway sends batches with `PutRecords` (plural), which is a separate IAM action;
- the **resource** is the ARN of `parcel-scans-staging`, not `parcel-scans`.

1. Look at the policy:

```bash
aws iam get-user-policy --user-name scan-gateway --policy-name depot-publish
```

2. Fix both fields in `policy.json` (`edit`):

```json
{
  "Sid": "PublishScans",
  "Effect": "Allow",
  "Action": ["kinesis:PutRecord", "kinesis:PutRecords"],
  "Resource": "arn:aws:kinesis:us-east-1:000000000000:stream/parcel-scans"
}
```

3. Replace the inline policy:

```bash
aws iam put-user-policy --user-name scan-gateway --policy-name depot-publish \
  --policy-document file://policy.json
```

4. `check` sends a real batch as scan-gateway, confirms the three records arrived, and makes sure the user still cannot write to `parcel-billing` or read from `parcel-scans`.

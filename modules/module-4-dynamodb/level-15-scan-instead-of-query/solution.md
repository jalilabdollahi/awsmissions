# Solution

Three things have to change.

1. **An index that matches the question** (region equals X, time greater than Y):

```bash
aws dynamodb update-table --table-name orbit-shipments \
  --attribute-definitions AttributeName=region,AttributeType=S AttributeName=shippedAt,AttributeType=N \
  --global-secondary-index-updates '[{"Create":{"IndexName":"by-region-time",
    "KeySchema":[{"AttributeName":"region","KeyType":"HASH"},{"AttributeName":"shippedAt","KeyType":"RANGE"}],
    "Projection":{"ProjectionType":"ALL"}}}]'
```

2. **A policy that grants Query and nothing else.** On real AWS an index has its own ARN (`table/orbit-shipments/index/by-region-time`) that a table-only policy does not cover, so list both. `Scan` must go:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": "dynamodb:Query",
    "Resource": [
      "arn:aws:dynamodb:us-east-1:000000000000:table/orbit-shipments",
      "arn:aws:dynamodb:us-east-1:000000000000:table/orbit-shipments/index/by-region-time"
    ]
  }]
}
```

```bash
aws iam put-user-policy --user-name orbit-report-svc --policy-name report-reads --policy-document file://report-policy.json
```

3. Change the job to use `dynamodb query --index-name by-region-time --key-condition-expression 'region = :r AND shippedAt > :t'` instead of `scan` (`workspace/report.sh`).

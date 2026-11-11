# Solution

The secret's rotation is configured with the ARN of `pelican-rotate-orders-db-v1`, a function that has been deleted, and with a 90 day interval. The replacement is `pelican-rotate-orders-db`.

```bash
aws secretsmanager describe-secret --secret-id pelican/orders-db/password
aws lambda list-functions --query 'Functions[].[FunctionName,FunctionArn]'

aws secretsmanager rotate-secret --secret-id pelican/orders-db/password \
  --rotation-lambda-arn arn:aws:lambda:us-east-1:000000000000:function:pelican-rotate-orders-db \
  --rotation-rules AutomaticallyAfterDays=30 \
  --no-rotate-immediately
```

`check` verifies rotation is enabled, that the stored function exists and is the orders database rotator, that the interval is at most 30 days, and that the secret still holds the database login.

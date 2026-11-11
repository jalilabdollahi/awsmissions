# Solution

Both statements name the right queues but the wrong ARNs: the consume statement says region `us-west-2` and the dead-letter statement says account `123456789012`. A queue ARN is `arn:aws:sqs:<region>:<account-id>:<queue-name>`, and IAM compares every part.

1. Ask SQS for the real ARNs:

```bash
aws sqs get-queue-attributes --queue-url $(aws sqs get-queue-url --queue-name orders-prod --query QueueUrl --output text) --attribute-names QueueArn
aws sqs get-queue-attributes --queue-url $(aws sqs get-queue-url --queue-name orders-dlq --query QueueUrl --output text) --attribute-names QueueArn
```

2. Put those ARNs in `policy.json` (`edit`): `arn:aws:sqs:us-east-1:000000000000:orders-prod` and `arn:aws:sqs:us-east-1:000000000000:orders-dlq`.
3. Apply it:

```bash
aws iam put-user-policy --user-name orderflow-consumer --policy-name consumer-access --policy-document file://policy.json
```

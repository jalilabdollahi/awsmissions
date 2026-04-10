# Solution

```bash
# Store the large payload in S3 first
aws s3 cp large-payload.json s3://message-payloads/large-payload.json

# Then send a small S3 reference through SQS
aws sqs send-message   --queue-url "$(aws sqs get-queue-url --queue-name mission-queue --query QueueUrl --output text)"   --message-body '{"bucket":"message-payloads","key":"large-payload.json"}'
```

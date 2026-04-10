# Solution

```bash
aws sqs create-queue --queue-name mission-dlq

QUEUE_URL="$(aws sqs get-queue-url --queue-name mission-queue --query QueueUrl --output text)"

aws sqs set-queue-attributes   --queue-url "$QUEUE_URL"   --attributes RedrivePolicy=file://redrive.json
```

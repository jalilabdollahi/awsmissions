# Solution

```bash
QUEUE_URL="$(aws sqs get-queue-url --queue-name mission-queue.fifo --query QueueUrl --output text)"

aws sqs set-queue-attributes   --queue-url "$QUEUE_URL"   --attributes ContentBasedDeduplication=true
```

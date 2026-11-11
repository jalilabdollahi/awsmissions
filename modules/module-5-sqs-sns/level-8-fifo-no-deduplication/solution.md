# Solution

FIFO queues refuse a message that has no deduplication id *unless* the queue can derive one. That is what `ContentBasedDeduplication` does: SQS takes the SHA-256 hash of the message body and uses it as the id. Identical bodies sent within 5 minutes then collapse into one message.

```bash
aws sqs get-queue-attributes --attribute-names ContentBasedDeduplication \
  --queue-url $(aws sqs get-queue-url --queue-name tidewater-payments.fifo --query QueueUrl --output text)

aws sqs set-queue-attributes \
  --queue-url $(aws sqs get-queue-url --queue-name tidewater-payments.fifo --query QueueUrl --output text) \
  --attributes ContentBasedDeduplication=true
```

This is an attribute that can be changed on a live queue, so there is no need to recreate it. Run `check`: the validator sends the same body twice without an id and expects a single copy in the queue.

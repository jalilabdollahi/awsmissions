# Solution

When a worker receives a message, SQS hides it for the queue's **visibility timeout**. This queue hides it for 2 seconds, but rendering takes up to 8, so the message becomes visible again mid-render and a second worker takes it.

1. Check the setting:

```bash
aws sqs get-queue-attributes --queue-url $(aws sqs get-queue-url --queue-name labelforge-jobs --query QueueUrl --output text) --attribute-names VisibilityTimeout
```

2. Raise it to comfortably above the slowest job (30 seconds leaves headroom) and well below the 2-minute retry limit:

```bash
aws sqs set-queue-attributes \
  --queue-url $(aws sqs get-queue-url --queue-name labelforge-jobs --query QueueUrl --output text) \
  --attributes VisibilityTimeout=30
```

3. Run `check`. The validator receives a job, waits 9 seconds without deleting it, and expects that it has not been handed out again.

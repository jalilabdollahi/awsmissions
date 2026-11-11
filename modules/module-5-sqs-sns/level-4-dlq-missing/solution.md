# Solution

A dead-letter queue is just another queue plus a **redrive policy** on the source queue.

1. Create the parking queue with 14-day retention:

```bash
aws sqs create-queue --queue-name ledgerlink-settlements-dlq \
  --attributes MessageRetentionPeriod=1209600
aws sqs get-queue-attributes --attribute-names QueueArn \
  --queue-url $(aws sqs get-queue-url --queue-name ledgerlink-settlements-dlq --query QueueUrl --output text)
```

2. Put the DLQ's ARN and a retry count (for example 4) into `redrive.json` (`edit`). The attribute value is a JSON document stored inside a JSON string, so the inner quotes stay escaped.

3. Apply it to the source queue:

```bash
aws sqs set-queue-attributes \
  --queue-url $(aws sqs get-queue-url --queue-name ledgerlink-settlements --query QueueUrl --output text) \
  --attributes file://redrive.json
```

4. Run `check`. The validator sends a message, receives it repeatedly without deleting it, and expects to find it in the DLQ.

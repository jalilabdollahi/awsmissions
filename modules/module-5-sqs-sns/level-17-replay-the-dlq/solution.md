# Solution

SQS can replay a dead-letter queue for you with a **message move task**. It moves messages (not copies), preserves their bodies and attributes, and can be monitored and cancelled.

```bash
aws sqs start-message-move-task \
  --source-arn arn:aws:sqs:us-east-1:000000000000:crescent-invoices-dlq \
  --destination-arn arn:aws:sqs:us-east-1:000000000000:crescent-invoices

aws sqs list-message-move-tasks \
  --source-arn arn:aws:sqs:us-east-1:000000000000:crescent-invoices-dlq
```

Omitting `--destination-arn` would move each message back to the queue it originally came from. Run `check` once the task shows `COMPLETED`.

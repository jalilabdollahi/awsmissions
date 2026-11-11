# Solution

`maxReceiveCount` is the number of times a message may be *received* before SQS parks it. With a value of 1, the first failed attempt already exhausts the budget, so a transient SMS hiccup sends healthy reminders to the DLQ.

1. Inspect the policy:

```bash
aws sqs get-queue-attributes --attribute-names RedrivePolicy \
  --queue-url $(aws sqs get-queue-url --queue-name pinecrest-sms --query QueueUrl --output text)
```

2. In `redrive.json` raise `maxReceiveCount` to a value between 3 and 10 (5 is a common choice), then apply it:

```bash
aws sqs set-queue-attributes \
  --queue-url $(aws sqs get-queue-url --queue-name pinecrest-sms --query QueueUrl --output text) \
  --attributes file://redrive.json
```

3. Run `check`. The validator fails one reminder twice and expects the third attempt to still be delivered, and then confirms that a message that always fails is parked within 10 attempts.

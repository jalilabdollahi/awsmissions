# Solution

The redrive policy names `mailroom-outbound-dead`, but the DLQ is called `mailroom-outbound-dlq`. SQS accepts a redrive policy whose target does not exist and then has nowhere to move messages, so after `maxReceiveCount` attempts they are dropped.

1. Compare the policy with the real queue:

```bash
aws sqs get-queue-attributes --attribute-names RedrivePolicy \
  --queue-url $(aws sqs get-queue-url --queue-name mailroom-outbound --query QueueUrl --output text)
aws sqs get-queue-attributes --attribute-names QueueArn \
  --queue-url $(aws sqs get-queue-url --queue-name mailroom-outbound-dlq --query QueueUrl --output text)
```

2. Replace `deadLetterTargetArn` in `redrive.json` with the real DLQ ARN, then apply it:

```bash
aws sqs set-queue-attributes \
  --queue-url $(aws sqs get-queue-url --queue-name mailroom-outbound --query QueueUrl --output text) \
  --attributes file://redrive.json
```

3. Run `check`. The validator fails a job on purpose and looks for it in the DLQ, and makes sure the two jobs that were already parked are still there.

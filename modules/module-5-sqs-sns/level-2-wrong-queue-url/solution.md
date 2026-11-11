# Solution

A queue URL is the address that `SendMessage` uses. The production parameter holds the URL of `ticketdesk-support-staging`, so every send succeeds against the wrong queue.

1. See what the API is configured with, and what the real URL is:

```bash
aws ssm get-parameter --name /ticketdesk/prod/support-queue-url
aws sqs get-queue-url --queue-name ticketdesk-support
```

2. Overwrite the parameter with the production URL:

```bash
aws ssm put-parameter --name /ticketdesk/prod/support-queue-url \
  --type String --overwrite \
  --value "$(aws sqs get-queue-url --queue-name ticketdesk-support --query QueueUrl --output text)"
```

3. Run `check`. The validator reads the parameter exactly like the API would, sends a ticket to that address, and looks for it in both queues.

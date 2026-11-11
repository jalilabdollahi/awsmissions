# Solution

Asynchronous invocations are fire-and-forget: if the function raises, Lambda (after any retries) drops the event unless you tell it where to send failures. The tool for that is an **on-failure destination** in the function's event invoke config.

1. See what is configured today:

```bash
aws lambda get-function-event-invoke-config --function-name sms-notifier
```

You'll find retries at 0 and no destination.

2. Add the queue as the failure destination. Use the `update-` form so the existing retry setting is merged and kept (the `put-` form would replace the whole config, bringing retries back to the default of 2):

```bash
aws lambda update-function-event-invoke-config --function-name sms-notifier \
  --destination-config '{"OnFailure":{"Destination":"arn:aws:sqs:us-east-1:000000000000:sms-failed-deliveries"}}'
```

3. Test it: invoke with a bad number and look in the queue.

```bash
aws lambda invoke --function-name sms-notifier --invocation-type Event \
  --cli-binary-format raw-in-base64-out --payload '{"id":"t1","to":"bad"}' /dev/null
aws sqs receive-message --queue-url "$(aws sqs get-queue-url --queue-name sms-failed-deliveries --query QueueUrl --output text)"
```

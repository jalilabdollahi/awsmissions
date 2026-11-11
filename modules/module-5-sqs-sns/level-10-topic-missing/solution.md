# Solution

Two things were lost in the rollback: the topic, and with it every subscription that belonged to it. Recreating only the topic would make `publish` succeed again while the radio queue stays empty.

```bash
aws sns create-topic --name lighthouse-storm-warnings
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:000000000000:lighthouse-storm-warnings \
  --protocol sqs \
  --notification-endpoint arn:aws:sqs:us-east-1:000000000000:harbor-radio-feed
```

Run `check`: the validator publishes a bulletin and waits for it to arrive in the queue.

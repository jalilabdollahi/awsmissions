# Solution

Creating a queue does not connect it to anything. Only a **subscription** makes a topic forward to it, and this topic has one subscription (fulfilment).

1. List the subscribers:

```bash
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:us-east-1:000000000000:bluebird-checkout-events
```

2. Subscribe the loyalty queue. The endpoint is the queue's **ARN**, not its URL:

```bash
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:000000000000:bluebird-checkout-events \
  --protocol sqs \
  --notification-endpoint arn:aws:sqs:us-east-1:000000000000:bluebird-loyalty
```

3. Run `check`: the validator publishes one event and expects a copy in both queues.

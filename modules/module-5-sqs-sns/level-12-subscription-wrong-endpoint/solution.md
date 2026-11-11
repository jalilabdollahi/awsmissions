# Solution

The subscription's endpoint is the staging queue's ARN. A subscription's endpoint and protocol cannot be edited after creation, so the fix is to replace it.

1. Find the subscription and its endpoint:

```bash
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:us-east-1:000000000000:quartz-invoice-events
```

2. Remove the wrong one and create the right one:

```bash
aws sns unsubscribe --subscription-arn <SubscriptionArn of the staging subscription>
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:000000000000:quartz-invoice-events \
  --protocol sqs \
  --notification-endpoint arn:aws:sqs:us-east-1:000000000000:quartz-invoices-prod
```

3. Run `check`. It publishes an invoice and confirms that it appears in the prod queue and not in the staging queue. Adding the prod subscription but keeping the staging one is not enough.

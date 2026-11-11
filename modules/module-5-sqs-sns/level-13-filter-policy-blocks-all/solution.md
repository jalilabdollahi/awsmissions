# Solution

By default a subscription filter policy is matched against the message's **attributes**, not against its body. The vendor product puts `eventType` inside the JSON body and sends no attributes, so the policy can never match.

1. Inspect the subscription:

```bash
aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:us-east-1:000000000000:cobalt-order-events
aws sns get-subscription-attributes --subscription-arn <SubscriptionArn>
```

`FilterPolicyScope` is missing, which means `MessageAttributes`.

2. Switch the scope to the body (the filter itself can stay as it is):

```bash
aws sns set-subscription-attributes --subscription-arn <SubscriptionArn> \
  --attribute-name FilterPolicyScope --attribute-value MessageBody
```

3. Run `check`: it publishes `order_created`, `order_cancelled` and `order_refunded` JSON events and expects only the last two in the queue.

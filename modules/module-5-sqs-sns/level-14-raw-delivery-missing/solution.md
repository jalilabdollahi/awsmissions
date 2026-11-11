# Solution

By default SNS wraps each message in a JSON envelope (`Type`, `MessageId`, `TopicArn`, `Message`, `Timestamp`, signature fields...) and the real payload is the string in `Message`. `RawMessageDelivery` removes the envelope and hands the original body to the queue.

1. Look at the subscription and at a delivered message body:

```bash
aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:us-east-1:000000000000:delta-cart-events
aws sns get-subscription-attributes --subscription-arn <SubscriptionArn>
```

2. Turn raw delivery on for the existing subscription. Do not recreate it: that would drop the `channel = web` filter.

```bash
aws sns set-subscription-attributes --subscription-arn <SubscriptionArn> \
  --attribute-name RawMessageDelivery --attribute-value true
```

3. Run `check`: it publishes one web event and one mobile event, then verifies the web body parses as the bare cart event and the mobile event is absent.

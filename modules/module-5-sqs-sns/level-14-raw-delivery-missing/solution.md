# Solution

```bash
SUB_ARN="$(aws sns list-subscriptions-by-topic   --topic-arn arn:aws:sns:us-east-1:000000000000:mission-topic   --query 'Subscriptions[0].SubscriptionArn'   --output text)"

aws sns set-subscription-attributes   --subscription-arn "$SUB_ARN"   --attribute-name RawMessageDelivery   --attribute-value true
```

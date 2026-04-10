# Solution

```bash
SUB_ARN="$(aws sns list-subscriptions-by-topic   --topic-arn arn:aws:sns:us-east-1:000000000000:mission-topic   --query 'Subscriptions[0].SubscriptionArn'   --output text)"

aws sns unsubscribe --subscription-arn "$SUB_ARN"

aws sns subscribe   --topic-arn arn:aws:sns:us-east-1:000000000000:mission-topic   --protocol sqs   --notification-endpoint arn:aws:sqs:us-east-1:000000000000:mission-queue
```

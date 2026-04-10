# Solution

```bash
QUEUE_ARN="arn:aws:sqs:us-east-1:000000000000:mission-queue"

aws sns subscribe   --topic-arn arn:aws:sns:us-east-1:000000000000:mission-topic   --protocol sqs   --notification-endpoint "$QUEUE_ARN"
```

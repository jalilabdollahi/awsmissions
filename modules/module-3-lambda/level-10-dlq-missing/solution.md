# Solution

```bash
aws lambda update-function-configuration   --function-name mission-function   --dead-letter-config TargetArn=arn:aws:sqs:us-east-1:000000000000:mission-dlq
```

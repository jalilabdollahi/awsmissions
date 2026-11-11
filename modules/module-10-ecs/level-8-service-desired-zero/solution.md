# Solution

The service is healthy by its own definition: it wants zero tasks and has zero. Scale it back up:

```bash
aws ecs describe-services --cluster sundial --services sundial-api --query 'services[0].[desiredCount,runningCount]'
aws ecs update-service --cluster sundial --service sundial-api --desired-count 2
```

Check `runningCount` until it reaches 2.

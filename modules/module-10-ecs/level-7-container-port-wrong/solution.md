# Solution

The target group health-checks `<task ip>:<registered port>`. The service registers the container port from its load-balancer mapping (8080), but the application listens on 3000, so the check fails forever.

1. In `task-definition.json` change `containerPort` from 8080 to 3000, then register a new revision.
2. Roll the service onto it and update the mapping so it registers 3000:

```bash
aws ecs register-task-definition --cli-input-json file://task-definition.json
aws ecs update-service --cluster invoicely --service invoice-api --task-definition invoice-api:2 \
  --load-balancers targetGroupArn=<invoice-tg arn>,containerName=app,containerPort=3000
```

Check with `aws elbv2 describe-target-health --target-group-arn <invoice-tg arn>`. You do not need to touch the target group.

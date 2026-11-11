# Solution

`journald` is a Linux-host driver. Fargate has no host you can reach, so the supported options are `awslogs`, `splunk` and `awsfirelens`. Replace the log configuration:

```json
"logConfiguration": {
  "logDriver": "awslogs",
  "options": {
    "awslogs-group": "/ecs/checkout-worker",
    "awslogs-region": "us-east-1",
    "awslogs-stream-prefix": "worker"
  }
}
```

```bash
aws ecs register-task-definition --cli-input-json file://task-definition.json
aws ecs update-service --cluster marigold --service checkout-worker --task-definition checkout-worker:2
aws logs filter-log-events --log-group-name /ecs/checkout-worker
```

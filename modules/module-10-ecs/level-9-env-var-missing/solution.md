# Solution

1. Find out why it exits. The task's stop reason only says the essential container exited (exit code 1); the reason is in the log group:

```bash
aws ecs list-tasks --cluster pulse --desired-status STOPPED
aws logs filter-log-events --log-group-name /ecs/pulse-ingest --query 'events[].message'
```

The script prints `FATAL: APP_MODE is not set (valid modes: api, worker)`. `api` is the HTTP frontend and is rejected for this service, so the consumer needs `worker`.

2. Add the variable to `task-definition.json`:

```json
"environment": [
  { "name": "QUEUE_NAME", "value": "pulse-events" },
  { "name": "APP_MODE", "value": "worker" }
]
```

3. Register it and roll the service:

```bash
aws ecs register-task-definition --cli-input-json file://task-definition.json
aws ecs update-service --cluster pulse --service pulse-ingest --task-definition pulse-ingest:2
```

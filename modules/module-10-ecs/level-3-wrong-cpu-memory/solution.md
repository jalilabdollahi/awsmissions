# Solution

Fargate accepts only fixed CPU/memory pairs. 256 CPU units allow 512-2048 MiB, 512 units allow 1024-4096 MiB, 1024 units allow 2048-8192 MiB, and so on. The container needs 1536 MiB, so 256 CPU would still fit at 2048 MiB, and 512/2048 is a balanced pick.

1. Edit `task-definition.json`: set `"cpu": "512"` and `"memory": "2048"`.
2. Register it:

```bash
aws ecs register-task-definition --cli-input-json file://task-definition.json
```

Any valid pair with memory >= 1536 up to 1 vCPU / 4 GiB passes.

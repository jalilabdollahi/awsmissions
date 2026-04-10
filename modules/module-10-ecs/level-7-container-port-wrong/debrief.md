# Port Mismatch

## Why This Matters
This mission practices a real troubleshooting pattern in ECS & Containers: Task definition exposes port 8080 but load balancer target group expects port 80

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- ECS
- Fargate
- task definitions
- tasks

# Permanently Unhealthy

## Why This Matters
This mission practices a real troubleshooting pattern in ECS & Containers: Container health check command is `CMD ["curl", "http://localhost/wrong-path"]` — always fails

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- ECS
- Fargate
- task definitions

# App Can't Access AWS

## Why This Matters
This mission practices a real troubleshooting pattern in ECS & Containers: Task starts but application inside container can't read from S3 — task role has no S3 permission

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- ECS
- Fargate
- task definitions
- roles
- tasks

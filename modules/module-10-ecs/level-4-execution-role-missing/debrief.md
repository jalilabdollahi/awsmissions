# Can't Pull Image

## Why This Matters
This mission practices a real troubleshooting pattern in ECS & Containers: Task fails to start — no `executionRoleArn` set, so ECS can't pull the ECR image or write logs

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- ECS
- Fargate
- task definitions
- policy debugging
- roles

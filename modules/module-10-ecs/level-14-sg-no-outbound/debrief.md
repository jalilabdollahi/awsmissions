# Locked Container

## Why This Matters
This mission practices a real troubleshooting pattern in ECS & Containers: Security group has no outbound rules — task can't pull image or call AWS services

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- ECS
- Fargate
- task definitions
- tasks

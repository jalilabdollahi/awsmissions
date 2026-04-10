# App Crash at Startup

## Why This Matters
This mission practices a real troubleshooting pattern in ECS & Containers: Task starts but application crashes because required env var `APP_MODE` not in task definition

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- ECS
- Fargate
- task definitions
- tasks

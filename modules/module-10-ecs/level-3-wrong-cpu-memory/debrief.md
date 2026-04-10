# Invalid Config

## Why This Matters
This mission practices a real troubleshooting pattern in ECS & Containers: Fargate task definition has CPU `256` with memory `256` — Fargate requires memory >= 512MB for 256 CPU units

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- ECS
- Fargate
- task definitions
- tasks

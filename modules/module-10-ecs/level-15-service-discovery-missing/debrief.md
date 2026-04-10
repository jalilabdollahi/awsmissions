# Can't Find Service

## Why This Matters
This mission practices a real troubleshooting pattern in ECS & Containers: Service A tries to reach Service B via DNS `service-b.local` — no Cloud Map service discovery configured

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- ECS
- Fargate
- task definitions

# SSM Blocked

## Why This Matters
This mission practices a real troubleshooting pattern in Secrets & Config: ECS task role is missing `ssm:GetParameter` permission — task crashes at startup

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- Secrets Manager
- SSM
- KMS
- roles
- parameter store

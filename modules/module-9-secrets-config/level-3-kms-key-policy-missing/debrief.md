# No Key Permission

## Why This Matters
This mission practices a real troubleshooting pattern in Secrets & Config: KMS key exists and is enabled but key policy doesn't grant the IAM role permission to use it

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- Secrets Manager
- SSM
- KMS
- policy debugging
- roles

# Stale Credentials

## Why This Matters
This mission practices a real troubleshooting pattern in Secrets & Config: Secret rotation was configured but rotation Lambda ARN is wrong — secret is never rotated

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- Secrets Manager
- SSM
- KMS
- lambda functions
- secrets

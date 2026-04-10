# Access Denied to Secret

## Why This Matters
This mission practices a real troubleshooting pattern in Secrets & Config: Secret exists but IAM role is missing `secretsmanager:GetSecretValue` permission

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- Secrets Manager
- SSM
- KMS
- policy debugging
- roles

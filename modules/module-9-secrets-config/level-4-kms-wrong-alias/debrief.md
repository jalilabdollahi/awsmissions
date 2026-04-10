# Wrong Key Name

## Why This Matters
This mission practices a real troubleshooting pattern in Secrets & Config: Application uses `alias/production-key` but key was created with alias `alias/prod-key`

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- Secrets Manager
- SSM
- KMS

# Path Confusion

## Why This Matters
This mission practices a real troubleshooting pattern in Secrets & Config: Application reads `/production/db/password` but parameter was created at `/prod/db/password`

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- Secrets Manager
- SSM
- KMS
- parameter store

# Wrong Key in JSON

## Why This Matters
This mission practices a real troubleshooting pattern in Secrets & Config: Secret exists as JSON `{"password": "abc123"}` but application reads key `db_password`

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- Secrets Manager
- SSM
- KMS
- secrets

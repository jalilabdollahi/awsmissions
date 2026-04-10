# Disabled Key

## Why This Matters
This mission practices a real troubleshooting pattern in Secrets & Config: KMS key exists but is disabled — encrypt/decrypt operations fail with `DisabledException`

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- Secrets Manager
- SSM
- KMS

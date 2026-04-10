# Plaintext Secret

## Why This Matters
This mission practices a real troubleshooting pattern in Secrets & Config: SSM parameter `/mission/config/api-key` is stored as `String` type — should be `SecureString` (encrypted)

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- Secrets Manager
- SSM
- KMS
- secrets
- parameter store

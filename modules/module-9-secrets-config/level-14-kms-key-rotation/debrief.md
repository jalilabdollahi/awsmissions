# Rotation Breaks Decrypt

## Why This Matters
This mission practices a real troubleshooting pattern in Secrets & Config: KMS key rotation was enabled but application has old key ARN hardcoded — decryption fails after rotation

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- Secrets Manager
- SSM
- KMS

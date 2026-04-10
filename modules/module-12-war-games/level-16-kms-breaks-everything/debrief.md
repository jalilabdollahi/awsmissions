# Encryption Lockout

## Why This Matters
This mission practices a real troubleshooting pattern in Production War Games: KMS key disabled + key policy missing IAM role + Lambda uses hardcoded key ARN (not alias) after rotation

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- incident response
- multi-service debugging
- production troubleshooting
- policy debugging
- roles

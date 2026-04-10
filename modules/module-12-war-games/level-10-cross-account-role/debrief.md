# The Missing Bridge

## Why This Matters
This mission practices a real troubleshooting pattern in Production War Games: Assume-role fails: wrong Principal in trust policy + missing ExternalId condition + user missing sts:AssumeRole

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- incident response
- multi-service debugging
- production troubleshooting
- policy debugging
- roles

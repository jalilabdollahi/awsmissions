# Almost Right

## Why This Matters
This mission practices a real troubleshooting pattern in IAM Foundations: Policy condition uses `StringEquals` for a value that requires wildcard matching — use `StringLike`

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- IAM
- roles
- policies
- policy debugging

# The Bad Condition

## Why This Matters
This mission practices a real troubleshooting pattern in IAM Foundations: Policy has a condition block using wrong key: `"aws:sourceIp"` when it should be `"aws:SourceAccount"` — condition never matches

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- IAM
- roles
- policies
- policy debugging

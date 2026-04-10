# The Wrong Path

## Why This Matters
This mission practices a real troubleshooting pattern in IAM Foundations: IAM user exists at path `/ops/` but policy ARN references `/dev/` — condition on path fails

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- IAM
- roles
- policies
- policy debugging

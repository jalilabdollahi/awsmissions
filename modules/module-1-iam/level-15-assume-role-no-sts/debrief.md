# Can't Switch Hats

## Why This Matters
This mission practices a real troubleshooting pattern in IAM Foundations: User policy is missing `sts:AssumeRole` — cannot switch to the target role

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- IAM
- roles
- policies
- policy debugging

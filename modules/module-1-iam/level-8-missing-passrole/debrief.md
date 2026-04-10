# The Blocked Handoff

## Why This Matters
This mission practices a real troubleshooting pattern in IAM Foundations: IAM user can create Lambda but can't assign an execution role — missing `iam:PassRole`

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- IAM
- roles
- policies
- policy debugging
- lambda functions

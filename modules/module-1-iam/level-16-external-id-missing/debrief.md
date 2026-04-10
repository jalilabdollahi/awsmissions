# The Missing Secret Handshake

## Why This Matters
This mission practices a real troubleshooting pattern in IAM Foundations: Role trust policy requires `sts:ExternalId` condition but caller doesn't provide it — AssumeRole denied

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- IAM
- roles
- policies
- policy debugging
- secrets

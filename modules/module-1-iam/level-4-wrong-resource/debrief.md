# The Locked Vault

## Why This Matters
This mission practices a real troubleshooting pattern in IAM Foundations: Policy grants `s3:GetObject` on `arn:aws:s3:::wrong-bucket/*` but app reads from `mission-bucket`

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- IAM
- roles
- policies
- policy debugging
- buckets

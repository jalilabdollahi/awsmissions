# Scope Creep

## Why This Matters
This mission practices a real troubleshooting pattern in IAM Foundations: Policy uses specific object ARN `arn:aws:s3:::bucket/specific.txt` but app accesses multiple objects — only that file is allowed

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- IAM
- roles
- policies
- policy debugging
- buckets

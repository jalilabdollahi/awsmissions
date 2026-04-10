# Watching the Wrong Door

## Why This Matters
This mission practices a real troubleshooting pattern in Lambda Functions: S3 trigger is configured but points to `wrong-bucket` instead of `uploads-bucket`

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- Lambda
- execution roles
- function configuration
- buckets

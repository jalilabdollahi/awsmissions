# Read-Only Trap

## Why This Matters
This mission practices a real troubleshooting pattern in S3 Mastery: Bucket policy only allows `s3:GetObject` — PutObject is denied

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- S3
- bucket configuration
- object access
- policy debugging
- buckets

# Wrong Trigger

## Why This Matters
This mission practices a real troubleshooting pattern in S3 Mastery: S3 event notification is configured but targets `s3:ObjectRemoved:*` instead of `s3:ObjectCreated:*`

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- S3
- bucket configuration
- object access

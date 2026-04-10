# Upload Goes Nowhere

## Why This Matters
This mission practices a real troubleshooting pattern in Production War Games: S3 event notification on wrong bucket + Lambda resource policy missing principal + DLQ not configured

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- incident response
- multi-service debugging
- production troubleshooting
- policy debugging
- buckets

# Data Exposure Incident

## Why This Matters
This mission practices a real troubleshooting pattern in Production War Games: S3 bucket has public access block disabled + bucket ACL is public-read + bucket policy allows `*` principal

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- incident response
- multi-service debugging
- production troubleshooting
- policy debugging
- buckets

# The Blocked Pipeline

## Why This Matters
This mission practices a real troubleshooting pattern in Production War Games: Lambda role missing `s3:GetObject` AND bucket policy has explicit Deny for Lambda role

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- incident response
- multi-service debugging
- production troubleshooting
- policy debugging
- roles

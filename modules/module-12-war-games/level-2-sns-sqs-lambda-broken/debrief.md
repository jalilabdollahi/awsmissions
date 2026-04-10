# The Silent Chain

## Why This Matters
This mission practices a real troubleshooting pattern in Production War Games: SNS→SQS→Lambda pipeline: SQS queue policy missing (SNS can't send) + Lambda concurrency is 0

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- incident response
- multi-service debugging
- production troubleshooting
- policy debugging
- lambda functions

# Double-Wrapped

## Why This Matters
This mission practices a real troubleshooting pattern in SQS & SNS: Lambda expects raw message body but SNS wraps it in an envelope — JSON parsing fails

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- SQS
- SNS
- event delivery
- lambda functions

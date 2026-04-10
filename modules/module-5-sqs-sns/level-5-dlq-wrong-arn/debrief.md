# Lost DLQ

## Why This Matters
This mission practices a real troubleshooting pattern in SQS & SNS: DLQ is configured but the ARN points to a non-existent queue — redrive fails silently

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- SQS
- SNS
- event delivery
- policy debugging
- queues

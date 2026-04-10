# No Safety Net

## Why This Matters
This mission practices a real troubleshooting pattern in SQS & SNS: Queue has no Dead Letter Queue — failed messages disappear after max receive count

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- SQS
- SNS
- event delivery
- policy debugging
- queues

# Message Ghost

## Why This Matters
This mission practices a real troubleshooting pattern in SQS & SNS: Visibility timeout is 5 seconds — workers take 30s to process, messages become visible again and are re-processed

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- SQS
- SNS
- event delivery
- queues

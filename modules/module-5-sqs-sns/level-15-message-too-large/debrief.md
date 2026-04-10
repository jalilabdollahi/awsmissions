# Message Size Exceeded

## Why This Matters
This mission practices a real troubleshooting pattern in SQS & SNS: Application sends 300KB messages — SQS limit is 256KB — sends fail

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- SQS
- SNS
- event delivery
- queues

# Duplicate Messages

## Why This Matters
This mission practices a real troubleshooting pattern in SQS & SNS: FIFO queue exists but `ContentBasedDeduplication` is disabled and application doesn't provide `MessageDeduplicationId` — duplicates processed

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- SQS
- SNS
- event delivery
- queues

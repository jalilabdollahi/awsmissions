# SNS Can't Send

## Why This Matters
This mission practices a real troubleshooting pattern in SQS & SNS: SNS topic configured to deliver to SQS queue but queue policy doesn't allow SNS to send — messages lost

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- SQS
- SNS
- event delivery
- policy debugging
- queues

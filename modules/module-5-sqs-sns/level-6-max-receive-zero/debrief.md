# Zero Tolerance

## Why This Matters
This mission practices a real troubleshooting pattern in SQS & SNS: `maxReceiveCount` in redrive policy is set to `0` — messages go to DLQ immediately on first receive

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- SQS
- SNS
- event delivery
- policy debugging

# Silent Failure

## Why This Matters
This mission practices a real troubleshooting pattern in CloudWatch & Logging: Error metric is being published but no CloudWatch alarm is configured — nobody gets alerted

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- CloudWatch
- logs
- alarms

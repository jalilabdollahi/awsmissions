# Logic Flipped

## Why This Matters
This mission practices a real troubleshooting pattern in CloudWatch & Logging: Composite alarm uses `ALARM(alarm-a) AND NOT ALARM(alarm-b)` but should trigger when both are in ALARM

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- CloudWatch
- logs
- alarms

# Backwards Alarm

## Why This Matters
This mission practices a real troubleshooting pattern in CloudWatch & Logging: Alarm uses `LessThanThreshold` to detect high error counts — should be `GreaterThanThreshold`

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- CloudWatch
- logs
- alarms

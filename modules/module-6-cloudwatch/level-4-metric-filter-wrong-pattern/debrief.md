# Filter Catches Nothing

## Why This Matters
This mission practices a real troubleshooting pattern in CloudWatch & Logging: Metric filter exists to count ERROR logs but pattern is `[ERROR]` when logs use `ERROR:` format

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- CloudWatch
- logs
- alarms

# Mismatched Pattern

## Why This Matters
This mission practices a real troubleshooting pattern in CloudWatch & Logging: EventBridge rule has `"source": ["aws.ec3"]` (typo) instead of `"aws.ec2"` — events never match

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- CloudWatch
- logs
- alarms

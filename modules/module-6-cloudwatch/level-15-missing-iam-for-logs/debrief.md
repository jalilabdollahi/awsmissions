# No Permission to Write

## Why This Matters
This mission practices a real troubleshooting pattern in CloudWatch & Logging: Lambda execution role is missing `logs:CreateLogStream` and `logs:PutLogEvents` permissions

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- CloudWatch
- logs
- alarms
- roles
- lambda functions

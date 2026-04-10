# Where Are My Logs?

## Why This Matters
This mission practices a real troubleshooting pattern in CloudWatch & Logging: Lambda function writes logs but log group `/aws/lambda/mission-function` doesn't exist — logs dropped

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- CloudWatch
- logs
- alarms
- lambda functions

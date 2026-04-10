# Flying Blind

## Why This Matters
This mission practices a real troubleshooting pattern in Production War Games: Lambda has no log group + metric filter on wrong log group + alarm period mismatch + no SNS action

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- incident response
- multi-service debugging
- production troubleshooting
- lambda functions
- alarms

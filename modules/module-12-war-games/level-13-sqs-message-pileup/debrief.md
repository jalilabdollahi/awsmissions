# Queue Meltdown

## Why This Matters
This mission practices a real troubleshooting pattern in Production War Games: DLQ ARN wrong in redrive policy + visibility timeout too low + no alarm on DLQ depth

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- incident response
- multi-service debugging
- production troubleshooting
- policy debugging
- alarms

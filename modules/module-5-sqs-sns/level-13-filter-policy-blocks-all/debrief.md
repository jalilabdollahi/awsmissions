# The Silence Filter

## Why This Matters
This mission practices a real troubleshooting pattern in SQS & SNS: SNS subscription has a filter policy `{"eventType": ["nonexistent"]}` — no messages pass through

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- SQS
- SNS
- event delivery
- policy debugging

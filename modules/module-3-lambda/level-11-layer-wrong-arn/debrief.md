# Missing Dependency

## Why This Matters
This mission practices a real troubleshooting pattern in Lambda Functions: Function references a Lambda layer ARN that doesn't exist — init fails

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- Lambda
- execution roles
- function configuration
- lambda functions

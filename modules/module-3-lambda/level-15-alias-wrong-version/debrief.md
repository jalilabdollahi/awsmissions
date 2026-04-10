# The Ghost Alias

## Why This Matters
This mission practices a real troubleshooting pattern in Lambda Functions: Lambda alias `production` points to version `5` which was deleted — invocations fail

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- Lambda
- execution roles
- function configuration
- lambda functions

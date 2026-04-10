# Wrong Trust

## Why This Matters
This mission practices a real troubleshooting pattern in Lambda Functions: Execution role exists but trust policy has `ec2.amazonaws.com` instead of `lambda.amazonaws.com`

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- Lambda
- execution roles
- function configuration
- policy debugging
- roles

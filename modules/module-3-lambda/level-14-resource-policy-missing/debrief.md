# Permission Denied by Lambda

## Why This Matters
This mission practices a real troubleshooting pattern in Lambda Functions: S3 configured to invoke Lambda but Lambda resource policy doesn't allow S3 service

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- Lambda
- execution roles
- function configuration
- policy debugging
- lambda functions

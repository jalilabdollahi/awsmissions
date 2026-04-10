# The Locked Door

## Why This Matters
This mission practices a real troubleshooting pattern in Lambda Functions: Lambda function URL is configured with `AuthType: AWS_IAM` — public HTTP requests return 403

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- Lambda
- execution roles
- function configuration
- lambda functions

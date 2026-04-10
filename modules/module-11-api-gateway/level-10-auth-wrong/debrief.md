# Authorization Required

## Why This Matters
This mission practices a real troubleshooting pattern in API Gateway: API requires AWS_IAM authorization but client expects no auth — all requests 403

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- API Gateway
- Lambda integration
- stages
- REST APIs

# Stream Silence

## Why This Matters
This mission practices a real troubleshooting pattern in Production War Games: DynamoDB Streams disabled + Lambda event source mapping wrong stream ARN + Lambda role missing `dynamodb:GetRecords`

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- incident response
- multi-service debugging
- production troubleshooting
- roles
- lambda functions

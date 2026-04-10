# No Index, No Query

## Why This Matters
This mission practices a real troubleshooting pattern in DynamoDB: Application queries a GSI named `email-index` but the index doesn't exist on the table

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- DynamoDB
- tables
- indexes

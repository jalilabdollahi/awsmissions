# The Silent Table

## Why This Matters
This mission practices a real troubleshooting pattern in DynamoDB: Lambda should process every table change — DynamoDB Streams are disabled

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- DynamoDB
- tables
- indexes
- lambda functions
- streams

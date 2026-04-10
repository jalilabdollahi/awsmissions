# Local Index Gap

## Why This Matters
This mission practices a real troubleshooting pattern in DynamoDB: Application queries with a Local Secondary Index `status-index` that doesn't exist — LSI must be created at table creation time

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- DynamoDB
- tables
- indexes

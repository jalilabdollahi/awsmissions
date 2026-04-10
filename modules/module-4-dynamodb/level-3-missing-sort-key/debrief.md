# One Key Short

## Why This Matters
This mission practices a real troubleshooting pattern in DynamoDB: Table has only a hash key but the application queries with both hash + sort key — query fails

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- DynamoDB
- tables
- indexes

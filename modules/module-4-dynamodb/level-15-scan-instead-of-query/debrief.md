# Full Table Scan

## Why This Matters
This mission practices a real troubleshooting pattern in DynamoDB: Application uses `Scan` on a large table with a filter — extremely slow and expensive

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- DynamoDB
- tables
- indexes

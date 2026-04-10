# Type Mismatch

## Why This Matters
This mission practices a real troubleshooting pattern in DynamoDB: Table's hash key `userId` is defined as type `N` (Number) but application sends String values — all writes rejected

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- DynamoDB
- tables
- indexes

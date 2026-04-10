# Out of Capacity

## Why This Matters
This mission practices a real troubleshooting pattern in DynamoDB: Table is in PROVISIONED mode with 1 RCU/WCU — application load causes constant throttling

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- DynamoDB
- tables
- indexes

# The Overprotective Guard

## Why This Matters
This mission practices a real troubleshooting pattern in DynamoDB: PutItem has a ConditionExpression `attribute_not_exists(id)` that prevents updating an existing item

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- DynamoDB
- tables
- indexes

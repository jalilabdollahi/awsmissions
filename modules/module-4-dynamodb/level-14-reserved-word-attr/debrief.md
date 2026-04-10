# Reserved Words

## Why This Matters
This mission practices a real troubleshooting pattern in DynamoDB: Attribute name `status` is a DynamoDB reserved word — query using it as an expression attribute fails

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- DynamoDB
- tables
- indexes

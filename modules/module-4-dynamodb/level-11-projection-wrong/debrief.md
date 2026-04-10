# Half the Picture

## Why This Matters
This mission practices a real troubleshooting pattern in DynamoDB: GSI `category-index` has `ProjectionType: KEYS_ONLY` but application needs all attributes

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- DynamoDB
- tables
- indexes

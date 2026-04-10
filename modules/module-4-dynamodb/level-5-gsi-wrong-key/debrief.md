# Wrong Index Key

## Why This Matters
This mission practices a real troubleshooting pattern in DynamoDB: GSI `email-index` exists but is keyed on `username` instead of `email` — queries return nothing

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- DynamoDB
- tables
- indexes

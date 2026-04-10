# Provisionless Pain

## Why This Matters
This mission practices a real troubleshooting pattern in DynamoDB: Application has spiky unpredictable traffic but table is in PROVISIONED mode with no auto-scaling

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- DynamoDB
- tables
- indexes

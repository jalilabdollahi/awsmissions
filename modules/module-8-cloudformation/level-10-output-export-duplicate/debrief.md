# Name Conflict

## Why This Matters
This mission practices a real troubleshooting pattern in CloudFormation: Two stacks both export a value with the same name `SharedBucketName` — second stack fails

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- CloudFormation
- stacks
- templates
- buckets

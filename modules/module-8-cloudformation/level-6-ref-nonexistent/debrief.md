# Missing Reference

## Why This Matters
This mission practices a real troubleshooting pattern in CloudFormation: `!Ref MyBucket` references a logical ID `MyBucket` that doesn't exist in the template

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- CloudFormation
- stacks
- templates
- buckets

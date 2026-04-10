# Unknown Resource

## Why This Matters
This mission practices a real troubleshooting pattern in CloudFormation: Template has `AWS::S3::Bukcet` (typo) instead of `AWS::S3::Bucket` — CREATE_FAILED

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- CloudFormation
- stacks
- templates
- buckets

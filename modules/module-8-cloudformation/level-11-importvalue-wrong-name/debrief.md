# Broken Cross-Stack Link

## Why This Matters
This mission practices a real troubleshooting pattern in CloudFormation: `!ImportValue SharedBucketName` — but the export is actually named `mission-SharedBucketName`

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- CloudFormation
- stacks
- templates
- buckets

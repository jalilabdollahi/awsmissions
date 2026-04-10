# Dangerous Delete

## Why This Matters
This mission practices a real troubleshooting pattern in CloudFormation: S3 bucket resource has no `DeletionPolicy` (defaults to Delete) — stack deletion will wipe data

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- CloudFormation
- stacks
- templates
- policy debugging
- buckets

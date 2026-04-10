# SAM Template Rejected

## Why This Matters
This mission practices a real troubleshooting pattern in CloudFormation: Template uses `AWS::Serverless::Function` but is missing `Transform: AWS::Serverless-2016-10-31`

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- CloudFormation
- stacks
- templates

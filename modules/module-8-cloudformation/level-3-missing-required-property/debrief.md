# Missing Requirement

## Why This Matters
This mission practices a real troubleshooting pattern in CloudFormation: `AWS::SQS::Queue` resource is missing required `QueueName` — wait, QueueName is optional. `AWS::IAM::Role` missing `AssumeRolePolicyDocument` (required)

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- CloudFormation
- stacks
- templates
- policy debugging
- roles

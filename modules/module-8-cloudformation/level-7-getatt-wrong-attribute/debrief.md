# Wrong Attribute

## Why This Matters
This mission practices a real troubleshooting pattern in CloudFormation: `!GetAtt MyFunction.Arn` should be `!GetAtt MyFunction.FunctionArn` — depends on resource type

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- CloudFormation
- stacks
- templates

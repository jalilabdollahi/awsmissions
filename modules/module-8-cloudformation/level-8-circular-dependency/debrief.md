# Going in Circles

## Why This Matters
This mission practices a real troubleshooting pattern in CloudFormation: Resource A has `DependsOn: B` and B has `DependsOn: A` — circular dependency error

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- CloudFormation
- stacks
- templates

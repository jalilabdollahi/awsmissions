# Wrong Condition Logic

## Why This Matters
This mission practices a real troubleshooting pattern in CloudFormation: Condition `IsProduction: !Equals [!Ref Env, dev]` — logic is inverted (true when env is dev, not prod)

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- CloudFormation
- stacks
- templates

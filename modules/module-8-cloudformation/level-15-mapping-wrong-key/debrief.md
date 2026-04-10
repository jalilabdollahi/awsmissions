# Missing Map Entry

## Why This Matters
This mission practices a real troubleshooting pattern in CloudFormation: `!FindInMap [RegionMap, !Ref AWS::Region, AMI]` — the `us-east-1` key is missing from the Mappings section

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- CloudFormation
- stacks
- templates

# Unguarded VPC

## Why This Matters
This mission practices a real troubleshooting pattern in Lambda Functions: Lambda VPC config has subnets but no security groups — cannot configure network interface

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- Lambda
- execution roles
- function configuration
- lambda functions
- VPCs

# The Unreachable Service

## Why This Matters
This mission practices a real troubleshooting pattern in Production War Games: ECS task in private subnet + no NAT route + security group blocks 443 egress + execution role missing ecr permission

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- incident response
- multi-service debugging
- production troubleshooting
- roles
- subnets

# No Route to Internet

## Why This Matters
This mission practices a real troubleshooting pattern in EC2 & Networking: VPC, subnet, and IGW exist but route table has no route to `0.0.0.0/0` via IGW

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- EC2
- VPC
- networking
- VPCs
- subnets

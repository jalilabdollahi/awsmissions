# Too Restrictive CIDR

## Why This Matters
This mission practices a real troubleshooting pattern in EC2 & Networking: Security group inbound rule has CIDR `0.0.0.0/32` (single IP) instead of `0.0.0.0/0`

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- EC2
- VPC
- networking

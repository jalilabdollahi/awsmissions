# Firewall in the Way

## Why This Matters
This mission practices a real troubleshooting pattern in EC2 & Networking: Network ACL has a DENY rule for port 80 with lower rule number than the ALLOW rule — HTTP blocked

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- EC2
- VPC
- networking

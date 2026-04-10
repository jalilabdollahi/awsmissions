# EC2 Can't Talk to AWS

## Why This Matters
This mission practices a real troubleshooting pattern in EC2 & Networking: Instance needs to call AWS APIs (SSM, S3) but has no IAM instance profile

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- EC2
- VPC
- networking
- roles
- REST APIs

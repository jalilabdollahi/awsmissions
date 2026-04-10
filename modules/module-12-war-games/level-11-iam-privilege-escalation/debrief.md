# Security Audit

## Why This Matters
This mission practices a real troubleshooting pattern in Production War Games: Role has `iam:CreateRole` + `iam:AttachRolePolicy` + `iam:PassRole` — can create admin role and escalate

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- incident response
- multi-service debugging
- production troubleshooting
- policy debugging
- roles

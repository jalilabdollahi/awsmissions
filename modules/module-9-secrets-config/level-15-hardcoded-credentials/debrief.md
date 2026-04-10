# Credentials in Code

## Why This Matters
This mission practices a real troubleshooting pattern in Secrets & Config: Lambda function has `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` hardcoded in environment variables

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- Secrets Manager
- SSM
- KMS
- roles
- lambda functions

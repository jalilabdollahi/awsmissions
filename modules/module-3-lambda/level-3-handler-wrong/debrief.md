# The Missing Door

## Why This Matters
This mission practices a real troubleshooting pattern in Lambda Functions: Function is deployed but handler is `main.handler` — file is actually `index.py` with function `lambda_handler`

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- Lambda
- execution roles
- function configuration
- lambda functions

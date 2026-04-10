# The Misspelled Gate

## Why This Matters
This mission practices a real troubleshooting pattern in IAM Foundations: Policy action has typo: `"s3:GetObjcet"` — IAM rejects all GetObject calls

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- IAM
- roles
- policies
- policy debugging

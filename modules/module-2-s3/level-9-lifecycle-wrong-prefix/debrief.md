# Eternal Storage

## Why This Matters
This mission practices a real troubleshooting pattern in S3 Mastery: Lifecycle rule exists to expire objects after 30 days but prefix is `logs/` while objects are under `app-logs/` — objects never expire

## Production Lesson
In real AWS incidents, the fastest path is usually to compare actual state with expected state, then fix the smallest misconfiguration that restores service safely.

## Key Concepts
- S3
- bucket configuration
- object access

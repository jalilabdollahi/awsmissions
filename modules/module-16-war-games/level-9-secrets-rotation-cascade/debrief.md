# Debrief: INC-9004, the credential crisis

## Root causes
1. **ARN-pinned IAM policy.** A Secrets Manager ARN ends with a random suffix generated at creation. Deleting and re-creating a secret yields a new ARN even though the name is identical, so every policy that pinned the old ARN stopped matching.
2. **Stale identifier in Lambda configuration.** Same cause, different place.
3. **Half-finished rotation.** Rotation moves labels in four steps: create a new version as `AWSPENDING`, set the password in the database, test, then promote it to `AWSCURRENT`. The tool died after step 2, so the database had the new password but the secret's `AWSCURRENT` still held the old one.

## Timeline
- 01:50 rotation starts; the database password is changed.
- 02:10 rotation tooling fails before promoting the new version.
- 02:25 the secret is deleted and re-created "to get unstuck"; the new password is loaded as pending.
- 02:40 the first 500 errors. Everyone checks the database, which is healthy.

## Why it cascaded
Each layer reported a different symptom: `AccessDenied` (IAM), `ResourceNotFound` (config), `authentication failed` (stale password). Fixing one revealed the next, and none of them were database problems.

## Lessons
- Reference secrets by name (or by name with a `-*` ARN suffix in IAM), never by a full ARN that embeds a random suffix.
- Do not delete a secret to unstick a rotation. Fix the stuck version labels; if you must delete, keep the recovery window.
- Make applications re-read secrets (or cache with a short TTL) so a rotation does not require redeploying.
- Alarm on rotation failures and run a post-rotation smoke test against the dependent service.

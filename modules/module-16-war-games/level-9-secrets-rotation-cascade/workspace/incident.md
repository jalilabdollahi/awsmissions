# SEV-1 INC-9004 - Claims portal cannot reach its database

Juniper Health. The member claims portal (`juniper-claims-api`) is returning
500s for every request since 02:40 UTC. The database is up and healthy.

## What the on-call told the channel
- 01:50 Security's quarterly credential rotation ran against
  `juniper/prod/db-credentials`.
- The rotation tooling failed halfway through. To "unblock it" an engineer
  deleted the secret (force, no recovery window) and re-created it with the
  same name, then loaded the new password as the pending version.
- The database password HAS been changed. The value the database accepts is
  mirrored (for drills only) in SSM parameter `/juniper/db/live-password`.
- Nobody updated the application side.

## How the API gets its credentials
Lambda `juniper-claims-api` reads the secret named in its `SECRET_ID`
environment variable and compares the password it finds with what the database
accepts. It runs as role `juniper-claims-role`. The on-call user `jn-oncall` can
assume that role for debugging.

## Reminders
- The role must be able to read ONLY this application's secret. The billing
  integration key `juniper/prod/billing-api-key` sits in the same account and
  belongs to another team.
- Secrets Manager ARNs end with a random six-character suffix, and the
  suffix changes when a secret is re-created.
- Secrets have versions with staging labels. Applications read `AWSCURRENT`.

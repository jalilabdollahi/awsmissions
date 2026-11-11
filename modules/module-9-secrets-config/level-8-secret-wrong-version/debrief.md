# Debrief: versions are immutable, labels are not

A Secrets Manager secret is a list of **versions**, each with an immutable value, and a set of **staging labels** attached to versions:

| Label | Meaning |
|---|---|
| `AWSCURRENT` | what `GetSecretValue` returns when no version is named |
| `AWSPREVIOUS` | the version that was current before; used for rollback and for overlap |
| `AWSPENDING` | a version being prepared by a rotation function |
| your own labels | any string, e.g. `canary` |

A label points at exactly one version at a time, and each version can carry several. `update-secret-version-stage` moves a label; when `AWSCURRENT` moves, Secrets Manager automatically gives `AWSPREVIOUS` to the version it left.

**Why the overlap matters.** Rotating a signing key or database password is a two-step dance: switch the consumers that *sign or log in* to the new value, while consumers that *verify* can accept both for a while. `AWSPREVIOUS` keeps the retired value fetchable for exactly that window.

**Mistakes to avoid**
- Pinning clients to a `VersionId`: after a rotation they keep using a value that eventually stops working, or breaks when old versions without labels are deleted (versions with no label are removed after about 24 hours). Fetch by stage, or not at all.
- "Rolling back" by writing the old value again with `put-secret-value` creates a third version and hides the history; moving labels is cleaner and reversible.
- Clients that cache the secret keep the old value until their cache expires. After fixing labels, check the cache TTL of your consumers.

Use `aws secretsmanager list-secret-version-ids --include-deprecated` as your first diagnostic for any "wrong value" incident.

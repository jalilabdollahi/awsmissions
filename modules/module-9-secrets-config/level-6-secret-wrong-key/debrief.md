# Debrief: a JSON secret is a contract about field names

Secrets Manager stores a string or binary blob. Many teams store JSON, and AWS' own database rotation templates expect fixed field names (`username`, `password`, `host`, `port`, `dbname`, `engine`). Consumers parse the JSON themselves, so a mismatch shows up as an application error (`KeyError`, `undefined`), never as a Secrets Manager error.

**Changing a secret safely**
- `put-secret-value` adds a **new version** and moves the label `AWSCURRENT` to it; the old version becomes `AWSPREVIOUS`. Consumers that fetch the default stage see the change on their next read, and you can roll back by moving labels.
- `update-secret --secret-string` does the same in one call.
- Deleting and recreating the secret loses the history, changes the ARN suffix and breaks IAM policies and resource references that used the old ARN.

**Design advice**
- Agree on the JSON schema once, document it next to the secret (its description or a tag), and add new fields rather than renaming old ones: removing or renaming is a breaking change.
- If you use managed rotation for RDS/Redshift/DocumentDB, keep the standard field names; the rotation function reads and rewrites them, and a rotation will *drop* fields it does not know about unless the function is customised. Consider whether extra alias fields like `user`/`pass` survive a rotation in your setup.
- Cache secret values in the client with a short TTL (the AWS SDK caching libraries do this) so a version change is picked up without a restart.

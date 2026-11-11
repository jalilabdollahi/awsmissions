# Solution

1. **Versioning and documents.** Set versioning back to `Enabled`. With `list-object-versions`, find each key's delete marker (`IsLatest: true`) and delete that marker by version id; the previous version becomes current again. That restores Brightwater and Calder. The Acme MSA's previous version is the corrupted one (`CORRUPTED`), so after removing its marker, `copy-object` its older, good version (the largest, `LastModified` earlier) onto the same key: the copy becomes the new current version, and history is preserved.
2. **Case index.** `aws dynamodb restore-table-to-point-in-time --restore-date-time <the time in /marlow/incident/last-good-time>` into a new table (for example `ml-case-index-restored`), wait for it to become `ACTIVE`, scan it and `put-item` every row into the live `ml-case-index`.
3. **Intern.** Replace `casework` with a policy that allows `s3:GetObject`, `s3:PutObject`, `s3:ListBucket` and `dynamodb:GetItem/PutItem/Query/Scan` only: no `s3:DeleteObject*` and no `dynamodb:DeleteItem`.

`check` reads each document's real content, scans the live table for the four cases, verifies versioning, and then acts as `ml-intern`: reading and writing must work, while deleting an object, a specific object version and a table item must be refused.

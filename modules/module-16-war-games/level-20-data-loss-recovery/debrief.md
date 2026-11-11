# Debrief: INC-6611, the Friday-evening wipe

## What the safety nets did and did not do
| Net | Outcome |
|---|---|
| S3 versioning | The deletes were only delete markers, so every document was recoverable. But one contract's latest real version was already corrupted, so "remove the markers" alone returned bad data. |
| Versioning later suspended | New deletes would now be permanent. The suspension was the quiet second incident. |
| DynamoDB PITR | Rows are recoverable to any second in the retention window, but restore always creates a new table; getting the rows back into the live name is a copy job. |
| IAM | The intern had `s3:*` and `dynamodb:*`, so one mistyped bucket name was enough to destroy everything. |

## Timeline
- Weeks ago: sync tool corrupts the Acme MSA. Nobody notices.
- Friday 16:40: recursive delete on the wrong bucket; loop over the table.
- Friday 16:55: storage job suspends versioning.
- Friday 17:10: associates report empty folders.

## Recovery principles
- Find the last good point in time first, then restore to that time, not to "now".
- A restore is a copy into a new location. Plan the swap-back (copy rows, or repoint the application) and verify counts and content.
- Prefer removing delete markers over re-uploading: it keeps the full history, which matters for legal evidence.
- Verify content, not just presence; the corrupted contract would pass a "file exists" check.

## Prevention
- Separate roles for "read and add" and "administer", with no delete rights in the day-to-day role. Add S3 Object Lock or MFA delete for records that must never disappear, and a bucket policy deny for `s3:DeleteObjectVersion`.
- Alarm on versioning being changed (CloudTrail `PutBucketVersioning`) and on mass `DeleteObject`/`DeleteItem` rates.
- Keep PITR on for every important table and test a restore quarterly, so the first restore is not during an incident.

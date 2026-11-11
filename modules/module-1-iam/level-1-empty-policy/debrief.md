# Debrief: list is not read

S3 splits its permissions across two resource types:

| Resource ARN | Example actions |
|---|---|
| bucket: `arn:aws:s3:::name` | `s3:ListBucket`, `s3:GetBucketLocation` |
| objects: `arn:aws:s3:::name/*` | `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` |

`harborline-reports` had the first kind of statement and none of the second. IAM does not infer one from the other: with no matching Allow the request is an implicit deny, so the dashboard could list names but never open a file.

**In real life**
- Dashboards and BI tools usually need exactly list + get. Resist `s3:*`; it also grants delete and policy changes.
- Scope object access to a prefix (`reports/*`) when the bucket mixes data of different sensitivity.
- Use `aws iam simulate-principal-policy` or the IAM policy simulator to test a single action before shipping a policy.
- `put-user-policy` replaces the whole policy of that name, so always send the complete document, not just the new statement.

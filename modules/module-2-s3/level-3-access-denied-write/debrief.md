# Debrief: bucket ARN versus object ARN

S3 has two resource levels and every action belongs to one of them:

| Level | ARN | Typical actions |
|---|---|---|
| Bucket | `arn:aws:s3:::name` | `ListBucket`, `GetBucketPolicy`, `PutBucketVersioning` |
| Object | `arn:aws:s3:::name/key...` | `GetObject`, `PutObject`, `DeleteObject`, `AbortMultipartUpload` |

A statement whose Action and Resource sit at different levels is valid JSON, saves without complaint, and never matches. That is why reads worked (their statement used `/*`) while writes silently failed.

**Why a prefix, not `/*`**
Granting `PutObject` on the whole bucket also lets the runner overwrite `releases/`. Overwriting a published release is exactly the kind of incident prefix scoping prevents. The same bucket can safely host several writers if each statement is scoped to its own prefix.

**In real life**
- When a "should work" policy fails, ask first: *at which level does this action operate?*
- `aws iam simulate-principal-policy` handles identity policies; for bucket policies the quickest test is the real call as the real principal, which is what this validator does.
- Writers rarely need `s3:DeleteObject`. If artifacts must be immutable, combine prefix scoping with versioning or Object Lock.

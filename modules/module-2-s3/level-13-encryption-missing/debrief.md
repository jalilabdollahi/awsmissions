# Debrief: default encryption is forward-looking, and key choice is a policy decision

**Three server-side options**
| Option | Key owner | Typical use |
|---|---|---|
| SSE-S3 (`AES256`) | S3 | baseline; free, no key control |
| SSE-KMS with `aws/s3` | AWS managed key | audit trail in CloudTrail, no custom key policy |
| SSE-KMS with a customer managed key | you | compliance: you control the key policy, rotation and grants |

Since January 2023 S3 encrypts every new object with SSE-S3 by default, so "no encryption" really means "not the encryption your policy requires". The requirement here (a specific CMK) is exactly the case that needs an explicit bucket default.

**Existing objects are untouched.** Changing the default never rewrites old data. Re-encrypt with `copy-object` onto the same key (small objects), S3 Batch Operations (millions of objects), or a fresh upload.

**Bucket Keys** make S3 derive per-object data keys from a bucket-level key, so KMS is called far less often. For busy buckets this cuts KMS request charges by up to ~99%.

**In real life**
- Using KMS adds a dependency: callers need `kms:GenerateDataKey` and `kms:Decrypt` on the key. A missing grant shows up as `AccessDenied` on S3 calls, which confuses people.
- Enforce encryption with a bucket policy denying `PutObject` when the `s3:x-amz-server-side-encryption` header is wrong, in addition to the default.
- Referencing the key by alias is convenient, but S3 stores the resolved key ARN. Deleting and recreating an alias does not change existing objects.

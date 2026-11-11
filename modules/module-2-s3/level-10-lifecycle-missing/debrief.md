# Debrief: invisible parts, and a PUT that replaces everything

**Multipart upload lifecycle.** A large upload is `CreateMultipartUpload`, many `UploadPart` calls, then `CompleteMultipartUpload` (or `AbortMultipartUpload`). Until one of the last two happens, the uploaded parts sit in the bucket and are charged at normal storage rates, yet `aws s3 ls` does not show them. Only `list-multipart-uploads` does.

**The fix has two timescales**
- *Now*: abort the existing stranded uploads by hand; a lifecycle rule only acts after the configured days.
- *Always*: an `AbortIncompleteMultipartUpload` rule with `DaysAfterInitiation` removes any upload still unfinished after N days. Choose an N longer than your slowest legitimate upload.

**Scope**
Abort rules can use a prefix filter, but they match uploads by *key*. Here an upload started under `tmp/`, so a rule limited to `exports/` would have missed it. An empty prefix is the safe default for this one rule type, since it never deletes completed objects.

**The replacement trap**
`PutBucketLifecycleConfiguration` has no "add rule" mode. It overwrites the whole configuration. Always `get-bucket-lifecycle-configuration`, add to the JSON, and send everything back.

**In real life**
- S3 Storage Lens and the `AllIncompleteMultipartUploadsBytes` metrics show how much you are paying for abandoned parts.
- Tools such as the AWS CLI and SDK transfer managers retry parts but may leave uploads behind when killed; your jobs should abort on shutdown signals.

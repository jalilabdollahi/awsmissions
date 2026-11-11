# Solution

Incomplete multipart uploads do not show up as objects, but their parts are stored and billed until the upload is completed or aborted. Two actions are needed.

1. See and abort what is stranded now:

```bash
aws s3api list-multipart-uploads --bucket datavault-exports
aws s3api abort-multipart-upload --bucket datavault-exports --key <key> --upload-id <id>   # for each upload
```

2. Add an abort rule that covers the *whole* bucket (a stray upload sits under `tmp/`, outside `exports/`), **next to** the existing rule. Append to `lifecycle.json`:

```json
{
  "ID": "abort-stale-multipart",
  "Status": "Enabled",
  "Filter": { "Prefix": "" },
  "AbortIncompleteMultipartUpload": { "DaysAfterInitiation": 7 }
}
```

```bash
aws s3api put-bucket-lifecycle-configuration --bucket datavault-exports \
  --lifecycle-configuration file://lifecycle.json
```

`put-bucket-lifecycle-configuration` replaces every rule. If you send only the new rule, the `exports/` transition to STANDARD_IA disappears, and the validator checks that it survived.

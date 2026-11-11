# Solution

The service is configured for `harborline-manifests-2026` (plural), but the migration only created `harborline-manifest-2026` (singular). Bucket names are exact; the service can only use the name in its configuration.

1. Compare the two names:

```bash
cat ingest.env
aws s3 ls
```

2. Create the bucket the service expects:

```bash
aws s3 mb s3://harborline-manifests-2026
```

You do not need to touch the IAM policy of `ingest-bot`: it already allows the right actions on the right bucket name. Type `check` and the validator uploads a manifest as `ingest-bot` and reads it back.

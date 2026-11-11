# Solution

A bucket that never had versioning turned on keeps exactly one copy per key; uploading to an existing key replaces it. Turn versioning on:

```bash
aws s3api get-bucket-versioning --bucket ledgerly-contracts      # prints nothing: never enabled
aws s3api put-bucket-versioning --bucket ledgerly-contracts \
  --versioning-configuration Status=Enabled
```

From now on each upload to the same key creates a new version with its own `VersionId`. The validator uploads one key twice as `contract-svc`, lists the versions and downloads the first one by its version id.

Enabling versioning cannot bring back the signed Orbit original that was already overwritten; it protects everything written from this point on.

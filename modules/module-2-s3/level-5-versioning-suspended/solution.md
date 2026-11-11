# Solution

Two things are wrong, and they need two different actions.

**1. Versioning is Suspended.** Suspended is not the same as off: old versions are kept, but new writes overwrite a single version with the id `null`. Switch it back:

```bash
aws s3api put-bucket-versioning --bucket pixelcart-feature-flags \
  --versioning-configuration Status=Enabled
```

**2. The live flags.json is the bad upload.** Find the last good version and promote it by copying it onto the same key (a copy creates a new, latest version):

```bash
aws s3api list-object-versions --bucket pixelcart-feature-flags --prefix flags.json
aws s3api copy-object --bucket pixelcart-feature-flags --key flags.json \
  --copy-source "pixelcart-feature-flags/flags.json?versionId=<good-version-id>"
```

The version with `"rollout": 50` has a UUID-style id; the garbage one has the id `null`. The validator reads flags.json as `flag-publisher`, then uploads a probe key twice and expects two distinct version ids.

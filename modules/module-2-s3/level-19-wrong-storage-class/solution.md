# Solution

An object's storage class cannot be edited in place. You rewrite it, and the standard way is a copy onto itself with a new class. There is also a second cause: the lifecycle rule that keeps archiving `live/`.

1. Rewrite each live object as STANDARD. Keep the default metadata directive (`COPY`): if you pass `--metadata-directive REPLACE` without repeating the Content-Type and user metadata, they are lost.

```bash
aws s3api copy-object --bucket hotline-media --key live/autumn-banner.png \
  --copy-source hotline-media/live/autumn-banner.png --storage-class STANDARD
aws s3api copy-object --bucket hotline-media --key live/site.css \
  --copy-source hotline-media/live/site.css --storage-class STANDARD
```

2. Remove the misdirected rule `age-out-media` from `lifecycle.json`, keep `archive-old-campaigns`, and apply the whole document:

```bash
aws s3api put-bucket-lifecycle-configuration --bucket hotline-media \
  --lifecycle-configuration file://lifecycle.json
```

(Re-pointing the rule at `archive/` would only duplicate the rule that already exists.) The validator checks storage class, Content-Type, metadata and content for `live/`, that `archive/` is still GLACIER, and the lifecycle rules.

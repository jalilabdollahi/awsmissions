# Solution

Lifecycle rules match object keys by **prefix**, from the first character. The debug rule's prefix is `logs/debug/`, but the real keys are `app-logs/debug/...`. `app-logs/...` does not *start with* `logs/`, so the rule never matches anything. The error rule's prefix is correct, which is why only the debug logs piled up.

1. Compare the rules with the real keys:

```bash
aws s3api get-bucket-lifecycle-configuration --bucket ember-app-logs
aws s3 ls s3://ember-app-logs/ --recursive
```

2. In `lifecycle.json` change the debug rule's prefix to `app-logs/debug/`.

3. Apply the full document:

```bash
aws s3api put-bucket-lifecycle-configuration --bucket ember-app-logs \
  --lifecycle-configuration file://lifecycle.json
```

An empty prefix (a rule for the whole bucket) would make the debug logs expire, but it would also delete the audit logs. The validator evaluates every stored key against the rules to catch that.

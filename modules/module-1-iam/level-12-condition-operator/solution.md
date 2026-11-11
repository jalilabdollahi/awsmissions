# Solution

`StringEquals` compares text literally. The condition value `matters/2025/*` contains a `*`, but with `StringEquals` that is just an asterisk character, so only a prefix that is literally `matters/2025/*` would match. The clerk's real prefixes (`matters/2025/`, `matters/2025/smith-v-jones/`) never do.

1. Change the operator to `StringLike`, which understands `*` and `?`:

```json
"Condition": { "StringLike": { "s3:prefix": "matters/2025/*" } }
```

2. Re-apply the policy:

```bash
aws iam put-user-policy --user-name ashgrove-clerk --policy-name clerk-browse --policy-document file://policy.json
```

3. `check` lists 2025 and a subfolder, opens a file, and confirms 2024 and the bucket root are still refused.

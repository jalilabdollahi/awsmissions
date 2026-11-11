# Solution

The policy document has no `Version` element. When `Version` is missing IAM falls back to the legacy `2008-10-17` language, which does not support policy variables, so `${aws:username}` is treated as literal text and the resource ARN never matches any real object.

1. Add `"Version": "2012-10-17"` as the first element of `policy.json` (`edit`).
2. A managed policy cannot be edited in place; publish a new version and make it the default:

```bash
aws iam create-policy-version \
  --policy-arn arn:aws:iam::000000000000:policy/home-folders \
  --policy-document file://policy.json \
  --set-as-default
```

3. `check` reads and writes as both users and makes sure they cannot read each other's folder.

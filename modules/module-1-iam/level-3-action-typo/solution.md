# Solution

Two action names in `thumbnailer` are misspelled: `s3:GetObjcet` and `s3:PutObjects`. IAM stores whatever text you give it, but at request time it compares the action string exactly, so neither statement ever matches and the requests fall through to the implicit deny.

1. In `policy.json` (`edit`), correct them to `s3:GetObject` and `s3:PutObject`.
2. Re-apply the policy:

```bash
aws iam put-user-policy \
  --user-name lantern-thumbs \
  --policy-name thumbnailer \
  --policy-document file://policy.json
```

3. Run `check`. It does a real read from the originals bucket, a real write to the thumbnails bucket, and confirms nothing wider was granted.

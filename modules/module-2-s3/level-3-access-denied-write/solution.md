# Solution

The `CiPublishesBuilds` statement has the right principal and the right action, but its `Resource` is `arn:aws:s3:::nimbus-build-artifacts`, the ARN of the *bucket*. `s3:PutObject` acts on *objects*, whose ARNs look like `arn:aws:s3:::nimbus-build-artifacts/<key>`. The statement therefore matches nothing the runner ever does.

1. Edit `bucket-policy.json` so the statement reads:

```json
{
  "Sid": "CiPublishesBuilds",
  "Effect": "Allow",
  "Principal": { "AWS": "arn:aws:iam::000000000000:user/ci-runner" },
  "Action": "s3:PutObject",
  "Resource": "arn:aws:s3:::nimbus-build-artifacts/artifacts/*"
}
```

2. Apply the whole document again (keep the other two statements):

```bash
aws s3api put-bucket-policy --bucket nimbus-build-artifacts --policy file://bucket-policy.json
```

Using `nimbus-build-artifacts/*` would also make uploads work, but then the runner could overwrite releases. The validator checks for that.

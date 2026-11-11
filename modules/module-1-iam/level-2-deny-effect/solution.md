# Solution

The inline policy `uploader-access` contains the right action and the right resource, but its write statement has `"Effect": "Deny"`. An explicit deny overrides every allow, so no other change can make uploads work while it is there.

1. Open the working copy of the policy (`edit`) and change the `WriteUserUploads` statement to `"Effect": "Allow"`:

```json
{
  "Sid": "WriteUserUploads",
  "Effect": "Allow",
  "Action": "s3:PutObject",
  "Resource": "arn:aws:s3:::pixelforge-uploads/incoming/*"
}
```

2. Replace the role's inline policy with the corrected document:

```bash
aws iam put-role-policy \
  --role-name pixelforge-uploader \
  --policy-name uploader-access \
  --policy-document file://policy.json
```

3. Confirm with `check`. The validator assumes the role as `upload-worker`, uploads a file to `incoming/`, and also makes sure the role still cannot write to `pixelforge-billing-exports` or outside `incoming/`.

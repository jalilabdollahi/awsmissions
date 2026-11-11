# Solution

S3 has two kinds of resource ARN. `arn:aws:s3:::bucket` is the bucket itself (needed for `s3:ListBucket`); `arn:aws:s3:::bucket/*` is the objects inside (needed for `GetObject`, `PutObject`, `DeleteObject`). The policy uses the bucket ARN for object actions, so they never match.

Edit `task-role-policy.json` so each action sits on the ARN type it works on:

```json
{ "Effect": "Allow", "Action": "s3:ListBucket", "Resource": "arn:aws:s3:::pixelmill-uploads" },
{ "Effect": "Allow", "Action": "s3:GetObject",  "Resource": "arn:aws:s3:::pixelmill-uploads/*" },
{ "Effect": "Allow", "Action": "s3:PutObject",  "Resource": "arn:aws:s3:::pixelmill-thumbs/*" }
```

```bash
aws iam put-role-policy --role-name pixelmill-task-role --policy-name resizer-s3 --policy-document file://task-role-policy.json
```

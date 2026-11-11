# Solution

`UploadsBucket` has `DependsOn: AnnouncePolicy` (S3 checks the topic permission when the notification is configured), while `AnnouncePolicy` uses `!GetAtt UploadsBucket.Arn` in its `aws:SourceArn` condition. Each waits for the other, so `create-stack` fails with a circular-dependency validation error.

Break the cycle on the side that does not need a lookup. The bucket name is fixed, so the ARN can be written directly:

```yaml
Condition:
  ArnLike:
    "aws:SourceArn": "arn:aws:s3:::granitepeak-uploads"
```

Keep `DependsOn: AnnouncePolicy` on the bucket, then deploy:

```bash
aws cloudformation create-stack --stack-name granitepeak-intake --template-body file://template.yaml
aws cloudformation wait stack-create-complete --stack-name granitepeak-intake
```

`check` verifies the topic policy still restricts publishing to that bucket, then subscribes a probe queue, uploads a file and expects the notification.

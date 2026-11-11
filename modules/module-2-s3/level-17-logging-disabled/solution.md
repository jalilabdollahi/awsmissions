# Solution

Three pieces: a log bucket, permission for the logging service to write into it, and the logging configuration on the source bucket.

1. Create the dedicated log bucket:

```bash
aws s3 mb s3://corvid-access-logs
```

2. Allow the S3 logging service principal to write log objects (edit `logging-bucket-policy.json`, then apply):

```json
{
  "Sid": "AllowS3LogDelivery",
  "Effect": "Allow",
  "Principal": { "Service": "logging.s3.amazonaws.com" },
  "Action": "s3:PutObject",
  "Resource": "arn:aws:s3:::corvid-access-logs/storefront/*",
  "Condition": { "ArnLike": { "aws:SourceArn": "arn:aws:s3:::corvid-storefront-assets" } }
}
```

```bash
aws s3api put-bucket-policy --bucket corvid-access-logs --policy file://logging-bucket-policy.json
```

3. Turn logging on:

```bash
aws s3api put-bucket-logging --bucket corvid-storefront-assets --bucket-logging-status \
  '{"LoggingEnabled":{"TargetBucket":"corvid-access-logs","TargetPrefix":"storefront/"}}'
```

The condition on `aws:SourceArn` stops other buckets from using your log bucket (the "confused deputy" problem). The validator accepts it with or without, but rejects a grant to `"*"`.

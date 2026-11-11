# Solution

Default encryption is a bucket setting that only applies to objects written *after* it is set, so there are two jobs.

1. Set the default to SSE-KMS with the clinic's key and Bucket Keys:

```bash
aws s3api put-bucket-encryption --bucket riverside-scans \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms",
        "KMSMasterKeyID": "alias/riverside-phi"
      },
      "BucketKeyEnabled": true
    }]
  }'
```

Leaving out `KMSMasterKeyID` would select the AWS managed key `aws/s3`, and `AES256` is SSE-S3: neither satisfies the policy.

2. Re-encrypt the scan that already exists by copying it onto itself with the encryption headers:

```bash
aws s3api copy-object --bucket riverside-scans --key scans/mri-0042.dcm \
  --copy-source riverside-scans/scans/mri-0042.dcm \
  --server-side-encryption aws:kms --ssekms-key-id alias/riverside-phi
```

Check with `aws s3api head-object` that `ServerSideEncryption` is `aws:kms` and the key matches. The validator resolves the alias you configured, so using the key id or ARN also works.

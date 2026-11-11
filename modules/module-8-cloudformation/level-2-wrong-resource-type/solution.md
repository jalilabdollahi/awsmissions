# Solution

The template declares the bucket as `AWS::S3::Bukcet` (the "c" and "k" are swapped). The stack reports `CREATE_COMPLETE`, but the event for `ScannedForms` carries a note that the type is not supported and nothing was created, and `aws s3 ls` shows no bucket.

1. Look at what the stack believes it owns:

```bash
aws cloudformation describe-stack-resources --stack-name brightwater-intake
aws cloudformation describe-stack-events --stack-name brightwater-intake
```

2. Fix the type in `template.yaml` (`edit`):

```yaml
  ScannedForms:
    Type: AWS::S3::Bucket
```

3. Update the stack and wait:

```bash
aws cloudformation update-stack --stack-name brightwater-intake --template-body file://template.yaml
aws cloudformation wait stack-update-complete --stack-name brightwater-intake
```

4. `check` uploads a test object to `brightwater-scans` and confirms that the stack, not a hand-made bucket, owns it.

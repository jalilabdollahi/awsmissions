# Solution

Release 2 asks for `!GetAtt ArchiveBucket.BucketArn`. `AWS::S3::Bucket` has no attribute called `BucketArn`; its ARN attribute is `Arn`. The IAM role update fails with `Policy document contains unresolved CloudFormation intrinsics`, CloudFormation rolls the whole update back, and the stack returns to release 1 in state `UPDATE_ROLLBACK_COMPLETE` (still updatable).

1. Read the failure:

```bash
aws cloudformation update-stack --stack-name orchard-reporting \
  --template-body file://template.yaml --capabilities CAPABILITY_NAMED_IAM
aws cloudformation describe-stack-events --stack-name orchard-reporting
```

2. Fix the attribute in `template.yaml` (`edit`):

```yaml
- !Join ["/", [!GetAtt ArchiveBucket.Arn, "*"]]
```

3. Roll it out again and wait:

```bash
aws cloudformation update-stack --stack-name orchard-reporting \
  --template-body file://template.yaml --capabilities CAPABILITY_NAMED_IAM
aws cloudformation wait stack-update-complete --stack-name orchard-reporting
```

4. `check` assumes the role as `report-bot` and uploads to both report buckets, and verifies that `orchard-payroll` is still off limits.

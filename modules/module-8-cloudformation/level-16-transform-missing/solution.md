# Solution

The template uses `AWS::Serverless::Function` but never declares `Transform: AWS::Serverless-2016-10-31`. Without the transform nothing expands the SAM shorthand: the stack reports success but contains a "resource" of type `AWS::Serverless::Function` and no Lambda function.

1. Check what the stack holds:

```bash
aws cloudformation describe-stack-resources --stack-name parcelhub-notifier
aws lambda list-functions
```

2. Declare the transform in `template.yaml` (`edit`):

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Transform: AWS::Serverless-2016-10-31
```

3. Recreate the stack (the expansion happens at creation):

```bash
aws cloudformation delete-stack --stack-name parcelhub-notifier
aws cloudformation wait stack-delete-complete --stack-name parcelhub-notifier
aws cloudformation create-stack --stack-name parcelhub-notifier --template-body file://template.yaml \
  --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND
aws cloudformation wait stack-create-complete --stack-name parcelhub-notifier
```

4. `check` verifies the function exists, is owned by the stack, and returns `courier-live` when invoked (the first invoke can take about ten seconds while the runtime starts).

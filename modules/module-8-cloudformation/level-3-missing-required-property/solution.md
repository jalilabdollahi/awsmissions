# Solution

`ExporterRole` has permissions but no `AssumeRolePolicyDocument`, a required property of `AWS::IAM::Role`. `aws iam get-role --role-name lumen-exporter` shows a trust policy with an empty `Statement` list, so every `sts:AssumeRole` is denied.

1. Add a trust policy to the role in `template.yaml` (`edit`):

```yaml
  ExporterRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: lumen-exporter
      AssumeRolePolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Effect: Allow
            Principal:
              AWS: !Sub "arn:aws:iam::${AWS::AccountId}:user/export-runner"
            Action: sts:AssumeRole
      Policies:
        ...
```

2. Update the stack:

```bash
aws cloudformation update-stack --stack-name lumen-export \
  --template-body file://template.yaml --capabilities CAPABILITY_NAMED_IAM
aws cloudformation wait stack-update-complete --stack-name lumen-export
```

3. `check` assumes the role as `export-runner` and uploads a file. It also confirms that `intern-sandbox` still cannot assume the role and that the role cannot write to `lumen-hr-records`.

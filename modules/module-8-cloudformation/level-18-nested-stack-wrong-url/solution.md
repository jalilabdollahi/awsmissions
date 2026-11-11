# Solution

There are three independent mistakes in the parent template.

1. **Wrong key in `TemplateURL`.** The error says the S3 object does not exist. The child lives at `shared/alerting/topic-stack.yaml`:

```bash
aws s3 ls s3://crescent-templates --recursive
```

```yaml
TemplateURL: https://s3.amazonaws.com/crescent-templates/shared/alerting/topic-stack.yaml
```

2. **Wrong parameter name.** The child declares `TeamName`, the parent passes `Team`; the child's required parameter is therefore missing (`Parameters: [TeamName] must have values`):

```yaml
Parameters:
  TeamName: billing
```

3. **Wrong output name.** The child's output is `AlertTopicArn`, not `Arn`. Fixing the first two makes the stack deploy, but the parent output would just contain the text `Alerts.Outputs.Arn`:

```yaml
Value: !GetAtt Alerts.Outputs.AlertTopicArn
```

Because every failed attempt leaves a dead stack behind, delete before each retry:

```bash
aws cloudformation delete-stack --stack-name crescent-platform
aws cloudformation wait stack-delete-complete --stack-name crescent-platform
aws cloudformation create-stack --stack-name crescent-platform --template-body file://template.yaml
aws cloudformation wait stack-create-complete --stack-name crescent-platform
```

`check` verifies the stack is healthy, that the child's topic exists, and that the parent's `AlertsTopicArn` output equals the real topic ARN.

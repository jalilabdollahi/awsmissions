# Solution

`saltmarsh-api` imports `saltmarsh-alerts-topic-arn`, which did not exist when the stack was first created. The create failed and CloudFormation rolled back to `ROLLBACK_COMPLETE`. The export exists now, so the template is correct, but a stack in this state cannot be updated.

1. Confirm the state and the original cause:

```bash
aws cloudformation describe-stacks --stack-name saltmarsh-api --query 'Stacks[0].StackStatus'
aws cloudformation describe-stack-events --stack-name saltmarsh-api
aws cloudformation list-exports
```

2. Delete and recreate:

```bash
aws cloudformation delete-stack --stack-name saltmarsh-api
aws cloudformation wait stack-delete-complete --stack-name saltmarsh-api
aws cloudformation create-stack --stack-name saltmarsh-api --template-body file://template.yaml
aws cloudformation wait stack-create-complete --stack-name saltmarsh-api
```

3. `check` verifies the shared stack was untouched and that `/saltmarsh/alerts-topic` now holds the exported ARN.

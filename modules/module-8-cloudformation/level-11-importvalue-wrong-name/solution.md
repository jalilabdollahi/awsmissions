# Solution

The template imports `ledgerline-audit-topic-arn` and `ledgerline-prod-audit-bucket`. Neither export exists: the platform stacks publish `ledgerline-<env>-audit-topic-arn` and `ledgerline-<env>-audit-bucket-name`.

1. See the real names and values:

```bash
aws cloudformation list-exports
```

2. Edit `template.yaml` (`edit`) so both imports use the production exports:

```yaml
Value: !ImportValue ledgerline-prod-audit-topic-arn
...
Value: !ImportValue ledgerline-prod-audit-bucket-name
```

3. The failed create left a `ROLLBACK_COMPLETE` stack. Delete it and deploy again:

```bash
aws cloudformation delete-stack --stack-name ledgerline-auditor
aws cloudformation wait stack-delete-complete --stack-name ledgerline-auditor
aws cloudformation create-stack --stack-name ledgerline-auditor --template-body file://template.yaml
aws cloudformation wait stack-create-complete --stack-name ledgerline-auditor
```

4. `check` reads both SSM parameters and verifies they hold the production topic ARN and bucket name, not the staging ones.

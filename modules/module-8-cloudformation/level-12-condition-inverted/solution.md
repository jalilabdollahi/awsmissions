# Solution

`IsProduction` is defined as `!Equals [!Ref Environment, dev]`, so it is true for dev and false for prod. Versioning, the pager topic and (through `IsSandbox: !Not [!Condition IsProduction]`) the debug topic all follow it, which inverts every production/sandbox decision.

1. Correct the condition in `template.yaml` (`edit`):

```yaml
Conditions:
  IsProduction: !Equals [!Ref Environment, prod]
  IsSandbox: !Not [!Condition IsProduction]
```

2. Update production, reusing its parameter value:

```bash
aws cloudformation update-stack --stack-name marlow-catalog \
  --template-body file://template.yaml \
  --parameters ParameterKey=Environment,UsePreviousValue=true
aws cloudformation wait stack-update-complete --stack-name marlow-catalog
```

CloudFormation creates the pager topic, switches the bucket to versioned and deletes the debug topic.

3. `check` verifies production, then deploys a throwaway dev copy of the stack's template to prove sandboxes still get the debug topic and no pager.

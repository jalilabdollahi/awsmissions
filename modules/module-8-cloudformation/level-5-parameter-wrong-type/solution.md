# Solution

`params.json` passes `"45s"` to `TimeoutSeconds`, which is declared `Type: Number` and flows into the Lambda `Timeout` property. The function fails to create (`For input string: "45s"` in the stack events), CloudFormation rolls the stack back, and it ends in `ROLLBACK_COMPLETE`.

1. Confirm the cause:

```bash
aws cloudformation describe-stack-events --stack-name quarry-resizer
```

2. Fix the value in `params.json` (`edit`): `"ParameterValue": "45"`.

3. A `ROLLBACK_COMPLETE` stack cannot be updated, so delete it and create it again:

```bash
aws cloudformation delete-stack --stack-name quarry-resizer
aws cloudformation wait stack-delete-complete --stack-name quarry-resizer
aws cloudformation create-stack --stack-name quarry-resizer \
  --template-body file://template.yaml --parameters file://params.json
aws cloudformation wait stack-create-complete --stack-name quarry-resizer
```

4. `check` confirms the stack is healthy, the function has a 45 second timeout, and the value came through the parameter.

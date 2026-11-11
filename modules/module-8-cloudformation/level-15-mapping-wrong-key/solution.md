# Solution

The `RegionSizing` map is keyed by region name, and the lookup uses `!Ref "AWS::Region"`, which is `us-east-1` here. The table, however, contains `us-east1` (missing a dash), so `FindInMap` finds nothing, the Lambda `MemorySize` is empty and the function fails to create. The stack rolls back to `ROLLBACK_COMPLETE`.

1. Read the failure:

```bash
aws cloudformation describe-stack-events --stack-name cobalt-reminders
```

2. Rename the key in `template.yaml` (`edit`): `us-east-1:` with `Memory: "1024"` and `Timeout: "20"`.

3. Remove the failed stack and deploy again:

```bash
aws cloudformation delete-stack --stack-name cobalt-reminders
aws cloudformation wait stack-delete-complete --stack-name cobalt-reminders
aws cloudformation create-stack --stack-name cobalt-reminders --template-body file://template.yaml
aws cloudformation wait stack-create-complete --stack-name cobalt-reminders
```

4. `check` reads the function's real memory and timeout (1024 MB, 20 s) and confirms the stack still uses `Fn::FindInMap`.

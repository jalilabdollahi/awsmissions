# Solution

`create-service` needs a registered task definition revision. `harbor-web:1` does not exist because the spec in `harbor-web.json` was never registered in this account.

```bash
aws ecs register-task-definition --cli-input-json file://harbor-web.json
bash deploy.sh
```

Revision numbers start at 1 for a family that has never been registered, which is why the script's `harbor-web:1` works afterwards. Confirm with `aws ecs describe-services --cluster harbor --services harbor-web`.

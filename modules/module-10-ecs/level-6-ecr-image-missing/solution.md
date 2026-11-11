# Solution

The stopped task's reason shows the registry could not find the tag:

```bash
aws ecs list-tasks --cluster hearth --desired-status STOPPED
aws ecs describe-tasks --cluster hearth --tasks <arn> --query 'tasks[0].stoppedReason'
```

`nginx:1.29.99-alpine` does not exist. The approved reference lives in Parameter Store:

```bash
aws ssm get-parameter --name /hearth/web/approved-image --query Parameter.Value --output text
```

Put that value into `task-definition.json`, register a new revision and launch again:

```bash
aws ecs register-task-definition --cli-input-json file://task-definition.json
bash deploy.sh
```

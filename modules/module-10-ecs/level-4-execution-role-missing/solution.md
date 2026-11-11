# Solution

Fargate uses the **task execution role** (not the task role) to pull the image, create log streams and fetch `secrets` before your code starts. The revision has none.

1. Create a role that ECS tasks can assume, attach the AWS-managed `AmazonECSTaskExecutionRolePolicy` (ECR pull + CloudWatch Logs), and add an inline policy for exactly one secret:

```bash
aws iam create-role --role-name payroll-exec-role --assume-role-policy-document file://trust.json   # principal ecs-tasks.amazonaws.com
aws iam attach-role-policy --role-name payroll-exec-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
aws iam put-role-policy --role-name payroll-exec-role --policy-name read-db-password --policy-document file://secret-policy.json
```

2. Add `"executionRoleArn": "arn:aws:iam::000000000000:role/payroll-exec-role"` to `task-definition.json`, register it, and update the service:

```bash
aws ecs register-task-definition --cli-input-json file://task-definition.json
aws ecs update-service --cluster payroll --service payroll-api --task-definition payroll-api:2
```

# Solution

A role's **effective permissions** are the intersection of its identity policies and its permissions boundary. The role policy allows `ssm:GetParameter`, but the boundary `quasar-self-service-boundary` only allows S3 and CloudWatch Logs, so SSM is cut off.

1. Compare the three policies:

```bash
aws iam get-role --role-name key-audit-role --query 'Role.PermissionsBoundary'
aws iam get-role-policy --role-name key-audit-role --policy-name audit-job
aws iam get-policy-version --policy-arn arn:aws:iam::000000000000:policy/quasar-self-service-boundary --version-id v1
```

2. Do not detach the boundary: it also keeps the leftover `dynamodb:*` harmless. Add only the missing permission to the boundary document (the workspace `boundary.json` is a copy of it):

```json
{
  "Sid": "ReadQuasarParameters",
  "Effect": "Allow",
  "Action": "ssm:GetParameter",
  "Resource": "arn:aws:ssm:us-east-1:000000000000:parameter/quasar/*"
}
```

3. Publish it as a new default version of the managed policy:

```bash
aws iam create-policy-version \
  --policy-arn arn:aws:iam::000000000000:policy/quasar-self-service-boundary \
  --set-as-default --policy-document file://boundary.json
```

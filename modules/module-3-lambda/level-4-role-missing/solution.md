# Solution

```bash
aws iam create-role   --role-name mission-lambda-role   --assume-role-policy-document file://trust-policy.json

aws iam put-role-policy   --role-name mission-lambda-role   --policy-name mission-lambda-logs   --policy-document file://policy.json

aws lambda update-function-configuration   --function-name mission-function   --role arn:aws:iam::000000000000:role/mission-lambda-role
```

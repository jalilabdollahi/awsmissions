# Solution

1. Create an execution role that Lambda can assume, allowed to read only the exporter's secret:

```bash
aws secretsmanager describe-secret --secret-id nimbus/exporter/api-token --query ARN --output text
aws iam create-role --role-name nimbus-exporter-role --assume-role-policy-document file://trust.json
aws iam put-role-policy --role-name nimbus-exporter-role --policy-name read-api-token --policy-document file://policy.json
```

with a trust policy for `lambda.amazonaws.com` and a policy allowing `secretsmanager:GetSecretValue` on that ARN.

2. Switch the function to the role and replace its environment (without the keys, keeping the other two variables):

```bash
aws lambda update-function-configuration --function-name nimbus-exporter \
  --role arn:aws:iam::000000000000:role/nimbus-exporter-role \
  --environment "Variables={APP_ENV=prod,TOKEN_SECRET_ID=nimbus/exporter/api-token}"
```

3. Disable the leaked key (then, once nothing breaks, delete it):

```bash
aws iam list-access-keys --user-name nimbus-ci
aws iam update-access-key --user-name nimbus-ci --access-key-id <key id> --status Inactive
```

`check` verifies the function config, the role's trust, uses the IAM simulator to confirm the role can read the exporter secret but not `nimbus/billing/master`, and that no access key of `nimbus-ci` is still active.

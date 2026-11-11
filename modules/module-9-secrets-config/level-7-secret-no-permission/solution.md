# Solution

The inline policy grants `secretsmanager:GetSecretValue` on `.../secret:quokka/prd/payments-api-*`, but the secret is named `quokka/prod/payments-api`. A resource ARN that matches nothing grants nothing.

1. Compare the policy with the secret's ARN:

```bash
aws iam get-role-policy --role-name quokka-api --policy-name quokka-secrets
aws secretsmanager describe-secret --secret-id quokka/prod/payments-api --query ARN
```

2. Fix the Resource in `policy.json` (`edit`):

```json
"Resource": "arn:aws:secretsmanager:us-east-1:000000000000:secret:quokka/prod/payments-api-*"
```

3. Reapply the policy:

```bash
aws iam put-role-policy --role-name quokka-api --policy-name quokka-secrets --policy-document file://policy.json
```

`check` assumes the role as `quokka-deployer`, reads the payments secret, and verifies that `quokka/prod/admin-console` and `quokka/staging/payments-api` are still refused.

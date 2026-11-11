# Solution

The stopped task reason says Secrets Manager could not find the secret: `cedar/db-credentails-Zq81Xa` is a typo (and the random suffix is made up). Look up the real ARN, which includes the six-character suffix:

```bash
aws secretsmanager describe-secret --secret-id cedar/db-credentials --query ARN --output text
```

In `task-definition.json` replace the secret part of both `valueFrom` values, keeping the `:username::` and `:password::` JSON-key suffixes:

```
arn:aws:secretsmanager:us-east-1:000000000000:secret:cedar/db-credentials-<suffix>:username::
```

Register the revision and update the service:

```bash
aws ecs register-task-definition --cli-input-json file://task-definition.json
aws ecs update-service --cluster cedar --service ledger-sync --task-definition ledger-sync:2
```

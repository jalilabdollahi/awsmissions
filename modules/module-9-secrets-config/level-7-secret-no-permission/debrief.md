# Debrief: secret ARNs and the six-character suffix

Every Secrets Manager secret has an ARN of the form

    arn:aws:secretsmanager:<region>:<account>:secret:<name>-<6 random characters>

The suffix is generated at creation, so you cannot know the full ARN in advance when you write a policy before the secret exists. That is why policies use `secret:<name>-*`. If you recreate a secret with the same name, the suffix changes; a policy with the wildcard keeps working and one with the pasted full ARN silently stops.

**Why "AccessDenied" with a correct-looking policy is so common**
- the path, environment word or region in the Resource ARN does not match exactly,
- the policy is attached to a different role than the one the service runs as,
- the secret is encrypted with a customer-managed KMS key and the role also needs `kms:Decrypt` on it,
- an SCP, permission boundary or explicit Deny wins over the Allow.

`aws iam simulate-principal-policy --policy-source-arn <role> --action-names secretsmanager:GetSecretValue --resource-arns <secret arn>` tells you what IAM decides and which statement matched.

**Least privilege for secrets**
- One role, the secrets it needs, no more. Wildcards belong at the end of a *path* (`secret:quokka/prod/payments-*`), not at the start.
- Use naming conventions (`team/env/service`) so one policy line covers a service's secrets across rotations.
- Add `secretsmanager:VersionStage` conditions if a role must only read `AWSCURRENT`.
- Resource policies on the secret can grant access too; in real AWS either side may allow same-account access.

# Debrief: how ECS injects secrets

When a container definition has `secrets`, the ECS agent resolves each `valueFrom` *before* the container starts (using the task execution role) and injects the value as an environment variable. If resolution fails the container is never created and the task stops with `ResourceInitializationError: unable to pull secrets or registry auth ...`. That is why the application's own logs are empty.

ARN anatomy: `arn:aws:secretsmanager:<region>:<account>:secret:<name>-<6 random chars>[:json-key:version-stage:version-id]`. Because the suffix is random, a name typed from memory is never a valid full ARN. Things that cause the same error: wrong region or account in the ARN, a deleted or scheduled-for-deletion secret, missing `secretsmanager:GetSecretValue` / `kms:Decrypt` on the execution role, or no network path to Secrets Manager (NAT or VPC endpoint).

The `:username::` form selects one key out of a JSON secret, so one secret can feed several variables.

Tip: always copy ARNs from `describe-secret` (or from CloudFormation/Terraform references), never retype them.

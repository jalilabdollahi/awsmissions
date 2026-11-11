# Debrief: two roles, two jobs

ECS tasks can have two different IAM roles and mixing them up is the number one ECS permissions mistake:

- **Execution role** (`executionRoleArn`): used by the ECS agent *on your behalf*, before and around your container: pull from ECR, push logs to CloudWatch, resolve `secrets` from Secrets Manager or SSM. Trusted by `ecs-tasks.amazonaws.com`.
- **Task role** (`taskRoleArn`): what your application code uses at runtime through the SDK (S3, DynamoDB, ...).

`AmazonECSTaskExecutionRolePolicy` covers ECR and logs, but not your secrets. You add `secretsmanager:GetSecretValue` for the specific secret ARN (plus `kms:Decrypt` if it uses a customer key). Granting `secretsmanager:*` on `*` would let every task in the cluster read every secret.

Notes: the emulator accepts a task definition with no role and still starts the container, whereas real Fargate fails the task with `ResourceInitializationError`; the validator therefore checks the role chain directly, using the IAM policy simulator. In real life, the stopped task's `stoppedReason` is where you will see the missing permission.

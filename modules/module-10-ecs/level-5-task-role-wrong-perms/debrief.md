# Debrief: bucket ARNs and object ARNs are different resources

IAM matches the request's resource against the policy's `Resource`. For S3:

| Action family | Resource |
|---|---|
| `s3:ListBucket`, `s3:GetBucketLocation` | `arn:aws:s3:::bucket` |
| `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` | `arn:aws:s3:::bucket/*` (or a prefix like `bucket/photos/*`) |

Getting this wrong produces an `AccessDenied` that looks mysterious because the bucket name is right there in the policy. The IAM policy simulator shows it immediately: `aws iam simulate-principal-policy --policy-source-arn <role> --action-names s3:GetObject --resource-arns arn:aws:s3:::bucket/key`.

Task role vs execution role: the application's AWS calls use the **task role** (here `pixelmill-task-role`), the execution role only serves the ECS agent. Keep them separate, and give each task its own role rather than sharing a broad one across services.

Tip: when a container gets AccessDenied, CloudTrail records the exact action and resource that was evaluated; copy them into the simulator.

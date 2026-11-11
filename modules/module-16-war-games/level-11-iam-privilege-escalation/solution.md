# Solution

All four paths are in the role's single inline policy, `ci-deploy`. Replace it with a policy that contains only what the pipeline needs:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {"Sid": "Lambda", "Effect": "Allow",
     "Action": ["lambda:CreateFunction", "lambda:UpdateFunctionCode", "lambda:UpdateFunctionConfiguration", "lambda:GetFunction"],
     "Resource": "arn:aws:lambda:us-east-1:000000000000:function:qf-*"},
    {"Sid": "PassStandardRoleOnly", "Effect": "Allow", "Action": "iam:PassRole",
     "Resource": "arn:aws:iam::000000000000:role/qf-svc-lambda-exec"},
    {"Sid": "Artifacts", "Effect": "Allow", "Action": ["s3:PutObject", "s3:GetObject"],
     "Resource": "arn:aws:s3:::qf-build-artifacts/*"}
  ]
}
```

- Path 1 (CreateRole + AttachRolePolicy) and path 4 (PutRolePolicy on itself) disappear when the IAM write actions are removed.
- Path 2 (PassRole `*`) is closed by listing only the standard execution role.
- Path 3 (CreateAccessKey `*`) disappears with the other IAM actions.

`check` uses the role to attempt each attack for real (create an admin role, create a function as `qf-platform-admin-role`, mint a key for `qf-platform-admin`, write a self-granting policy) and confirms the deploy duties still work.

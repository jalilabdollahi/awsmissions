# Debrief: Cognito admin APIs are ordinary IAM actions on a pool ARN

Everything an application does *as a signed-in user* (`InitiateAuth`, `SignUp`, `GetUser`) needs no AWS credentials. Everything it does *about* users from the backend (`AdminCreateUser`, `AdminSetUserPassword`, `AdminAddUserToGroup`, `ListUsers`, `AdminDeleteUser`, ...) is an authenticated AWS API call, and IAM decides it like any other: action plus resource.

The resource is the **user pool ARN**: `arn:aws:cognito-idp:<region>:<account>:userpool/<pool-id>`. The pool id is generated when the pool is created, so a policy that hard-codes it breaks the moment the pool is rebuilt, whether through a migration, a CloudFormation replacement, or a "delete and recreate" shortcut. The error is a plain `AccessDeniedException`, and it looks identical to "action missing", which is why there were two bugs to find here.

**How to debug**
1. The error names the denied action. List what the policy allows for that action, and with which `Resource`.
2. Compare the ARN character by character with `describe-user-pool --query UserPool.Arn`.
3. Add actions one at a time as the job needs them. The backend's code tells you the exact list.

**In real life**
- Do not grant `cognito-idp:*` or `Resource: "*"` to make the error go away. A backend that can create users can mint accounts; one that can also delete them can lock out your whole company.
- Reference the pool by `!GetAtt UserPool.Arn` in CloudFormation or `userPool.userPoolArn` in CDK, so the policy follows the pool.
- Separate duties: an onboarding job rarely needs `AdminDeleteUser`, `AdminDisableUser` or `UpdateUserPool`. Incident tooling may; give it its own role.
- Condition keys are limited for Cognito. The pool ARN is your main scoping tool, so keep different populations (staff, contractors, customers) in different pools.

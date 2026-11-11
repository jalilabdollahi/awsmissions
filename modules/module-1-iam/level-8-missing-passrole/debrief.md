# Debrief: PassRole is the privilege-escalation gate

When you create a Lambda function (or an EC2 instance, an ECS task, a Glue job...) you give it a role. The service later uses that role's permissions. So *whoever can attach a role can effectively use its permissions*, by writing code that runs under it. AWS protects that with a dedicated permission, `iam:PassRole`, evaluated against the **role's ARN**.

Notice that it is not an API you can call; it is only checked as part of other calls such as `lambda:CreateFunction`. That is why it is easy to forget and why the error mentions `iam:PassRole` rather than Lambda.

**Why `Resource: "*"` is dangerous:** a user with `lambda:CreateFunction` plus `iam:PassRole` on `*` can create a function using an admin role, invoke it, and do anything the admin can. The fix here lists exactly one role.

**In real life**
- Combine `iam:PassRole` with the `iam:PassedToService` condition so the role can only be handed to the intended service.
- Review any policy that has `PassRole` on `*`; Access Analyzer and Security Hub flag them.
- Pipelines should have a narrow list of roles they may pass, ideally with a naming convention (`arn:...:role/app-*`) plus a permission boundary on those roles.

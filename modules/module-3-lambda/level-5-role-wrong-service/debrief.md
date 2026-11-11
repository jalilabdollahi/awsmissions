# Debrief: trust is about who may wear the role

Every role answers two questions:

- **Who may assume me?** The trust policy (`AssumeRolePolicyDocument`). It is a resource policy attached to the role.
- **What may I do once assumed?** The permissions policies.

The principal of a trust statement decides who is allowed to call `sts:AssumeRole`. For AWS services the principal is a service name: `lambda.amazonaws.com` for Lambda, `ec2.amazonaws.com` for instance profiles, `ecs-tasks.amazonaws.com` for ECS tasks, `states.amazonaws.com` for Step Functions. Copying a role between compute types and forgetting to change that string is one of the most common causes of "Lambda cannot assume the role" in real accounts. On AWS you see it as an error from `create-function` or `update-function-configuration`: *The role defined for the function cannot be assumed by Lambda.*

**Floci note:** this emulator does not evaluate the trust policy when a function runs, so the checker inspects the trust document itself, then confirms the function still works with the role's permissions intact.

**Safe editing.** `update-assume-role-policy` replaces the entire document. Statements for other principals (here the CI user) disappear if you write a fresh one-liner. Always fetch, edit, put back.

**In real life**
- Leaving a stale `ec2.amazonaws.com` statement in a Lambda role is a privilege-escalation path: anyone who can launch an instance with that role can use its permissions.
- Use `aws iam simulate-custom-policy` or Access Analyzer findings to review trust policies for `*` principals.
- Conditions like `aws:SourceArn` / `aws:SourceAccount` in a service trust prevent the confused-deputy problem.

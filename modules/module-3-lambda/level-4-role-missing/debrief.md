# Debrief: two policies make an execution role

An execution role has two independent halves, and both must be right:

1. **Trust policy** (who may assume the role). For Lambda the principal is the *service* `lambda.amazonaws.com`. Without it Lambda cannot obtain credentials for your code at all.
2. **Permissions policy** (what the role may do). This is what your code's AWS SDK calls are checked against, while the function runs.

The function stores only the role's ARN. Deleting the role does not touch the function; it just leaves a dangling reference that fails when Lambda tries to assume it. IAM roles are looked up by name each time, so a *new* role with the same name would have worked as well, but a different name needs `update-function-configuration --role`.

**Why the legal-hold bucket matters.** The archiver lets callers override the target bucket. If the replacement role was created with `s3:*` on `*` (the classic "just make it work" move), the override would let anyone invoking the function overwrite evidence. Granting one action on one prefix means that even a code bug or a malicious event cannot go further than the policy does. The checker therefore invokes the function with the override and expects a refusal.

**In real life**
- Cleaning up "unused" roles: check `aws iam get-role --query Role.RoleLastUsed`, and search for function references (`aws lambda list-functions --query "Functions[].[FunctionName,Role]"`) before deleting anything.
- `logs:*` on the log group of the function is all the logging permission it ever needs; the AWS managed policy `AWSLambdaBasicExecutionRole` provides exactly that.
- IAM Access Analyzer can generate a least-privilege policy from CloudTrail activity once the function has run for a while.

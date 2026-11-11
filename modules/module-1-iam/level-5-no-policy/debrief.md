# Debrief: a role with a trust policy but no permissions can do nothing

An IAM role has two independent halves:

- the **trust policy** says *who may assume* the role (here: the Lambda service),
- the **permissions policies** say *what the role may do* once assumed.

A brand-new role has an empty second half. Lambda happily runs your code with that role's credentials, but every SDK call comes back `AccessDenied`. The function itself is fine; the code even reached S3.

**In real life**
- Start from a narrow policy and add what CloudWatch Logs or CloudTrail shows is denied. Starting with `AmazonS3FullAccess` is faster, but you rarely come back to tighten it.
- Real Lambda functions also need `logs:CreateLogGroup`, `logs:CreateLogStream` and `logs:PutLogEvents` (the managed policy `AWSLambdaBasicExecutionRole`) to write their logs.
- Give each function its own role. A shared "lambda-role" slowly accumulates the union of every function's permissions.
- Permission changes apply to the next invocation; you do not redeploy the function.

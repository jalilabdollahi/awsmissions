# Debrief: two policies guard every Lambda call

When API Gateway invokes a function, AWS checks two independent things:

1. **Who may call this function?** The function's **resource-based policy**. This is what `lambda add-permission` edits. API Gateway is a service principal (`apigateway.amazonaws.com`), so it needs an explicit statement.
2. **What may the function do?** Its execution role. Unrelated to invocation.

(For integrations that use an IAM role instead, `--credentials`, API Gateway assumes that role and the role's identity policy needs `lambda:InvokeFunction`. Then the function policy is not involved.)

The grant should name the API that is calling: `--source-arn arn:aws:execute-api:REGION:ACCOUNT:API_ID/STAGE/METHOD/PATH`. Without it, **any API Gateway in any account** that learns the function ARN could invoke it (the classic confused-deputy hole). With `/*/*/*`, every method of your API can call it, which is fine for a proxy function but too wide for one that serves a single route.

Why a rebuilt API breaks things: the API id is generated. A new API gets a new id, and a policy that names the old one no longer matches, so the invocation is refused (real API Gateway: HTTP 500 with "Invalid permissions on Lambda function" in the execution log). The leftover statement is also a lingering permission. Policies pile up quietly; `get-policy` is the only place to see them.

Practical tips:
- IaC modules should create the permission from the API resource itself, so the ids can never drift.
- Use distinct, meaningful statement ids; `remove-permission --statement-id` is the only way to delete a single grant.
- This emulator does not enforce Lambda resource policies, so the symptom is invisible locally. That is why this mission inspects the policy directly. In real AWS you would see it in the API's CloudWatch execution logs and as 500s from the stage.

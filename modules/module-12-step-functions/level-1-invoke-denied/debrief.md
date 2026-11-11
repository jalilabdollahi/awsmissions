# Debrief: a state machine is only as powerful as its execution role

Step Functions does not call your Lambda function with *your* credentials. When the Task state runs, the service assumes the **execution role** you gave the state machine and makes the `lambda:InvokeFunction` call with it. Two things must line up:

- the role's **trust policy** lets `states.amazonaws.com` assume it (that part was fine here), and
- the role's **permissions** allow what the definition does.

The role Tidewater copied came from a project that only used X-Ray, so it carried no permission to invoke anything.

**Where to look.** The execution fails, but the useful message lives one level down, in `get-execution-history`. `describe-execution` only shows a summary; the `LambdaFunctionFailed` event carries `Lambda.AccessDeniedException` and the exact action and resource that were refused.

**In real life**
- Scope `lambda:InvokeFunction` to the function ARNs the workflow really calls. If you use aliases or versions, the resource is `...:function:name:*` or the alias ARN.
- Each service integration needs its own actions on the role: `sqs:SendMessage`, `dynamodb:PutItem`, `sns:Publish`, `states:StartExecution`, and so on. The "Create state machine" console wizard can generate them for you; infrastructure as code usually cannot.
- Do not reuse execution roles between workflows. When a workflow is retired, its role goes with it.

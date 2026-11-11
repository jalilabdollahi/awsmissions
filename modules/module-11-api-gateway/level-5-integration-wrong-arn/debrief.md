# Debrief: the integration URI is a string nobody validates for you

For a Lambda integration, the `uri` has a rigid shape:

`arn:aws:apigateway:{region}:lambda:path/2015-03-31/functions/{FUNCTION_ARN}/invocations`

API Gateway stores whatever string you give it. A typo in the function name, a wrong region or the wrong account id is accepted without complaint at configuration time and only blows up when a client calls (a 5xx with a message such as "Function not found" or, on real AWS, a generic 500 plus an `Execution failed due to configuration error` line in the execution logs).

Why it is dangerous in the other direction too: **similarly named targets**. `invoice-renderer-staging` accepts the same payload, so "fixing" the error by picking the first function that autocompletes is easy and wrong. The API still returns 200, and nobody notices that customers see sandbox data until finance does.

Habits:
- Build URIs from the real ARN: `aws lambda get-function --function-name X --query Configuration.FunctionArn`, not by hand.
- Prefer **aliases** (`...:function:invoice-renderer:live`) in integrations. You can then roll a function forward or back without touching the API. Remember to add the invoke permission on the alias ARN.
- Turn on execution logging on a stage (CloudWatch) while debugging; it prints the exact URI API Gateway tried.
- `update-integration` with `op=replace,path=/uri` changes just the URI and keeps the rest of the integration intact.
- Redeploy the stage so the change goes live on real AWS.

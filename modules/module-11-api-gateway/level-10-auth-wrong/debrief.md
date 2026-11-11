# Debrief: 401, 403 and the identity source

A Lambda authorizer sits in front of the integration. For a **TOKEN** authorizer the flow is:

1. API Gateway reads the **identity source** (a header, query string parameter or stage variable). If it is missing or empty, the request is rejected with **401 Unauthorized** without invoking your function.
2. Otherwise it invokes the authorizer with `authorizationToken` and `methodArn`.
3. The function returns an IAM-style policy. `Allow` on the method ARN lets the request through to the integration; `Deny` produces **403 Forbidden**.
4. The result can be cached per token for `authorizerResultTtlInSeconds` (default 300 s), so a revoked token may keep working for minutes. Mind it when debugging a change that "does not take effect".

So 401 means "I could not find credentials where you told me to look" and 403 means "I found them and the authorizer refused". That distinction is the fastest diagnostic you have.

Other things worth knowing:
- A **REQUEST** authorizer can combine several identity sources (headers, query strings, stage variables, context); all must be present or the answer is 401.
- Optionally validate the token's format with `identityValidationExpression` to save a Lambda invocation on obviously invalid tokens.
- Authorizer `context` values (strings, numbers, booleans) are passed to the integration as `event.requestContext.authorizer.*`, which is the clean way to hand the caller's identity downstream.
- Never fix a failing authorizer by setting the method to `NONE`. If you need to test, use a separate stage.
- The authorizer function also needs a permission for `apigateway.amazonaws.com` to be invoked (real AWS); the console adds it for you, the CLI does not.

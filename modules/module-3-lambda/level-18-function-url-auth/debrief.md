# Debrief: three switches in front of a function URL

A **function URL** is a dedicated HTTPS endpoint for one function (`https://<id>.lambda-url.<region>.on.aws`). No API Gateway, no extra cost. Its security model has layers:

1. **`AuthType`**
   - `AWS_IAM`: callers must sign requests with SigV4 and have `lambda:InvokeFunctionUrl`. Perfect for service-to-service calls, impossible for a plain browser.
   - `NONE`: no signature needed.
2. **Resource-based policy.** With `NONE` Lambda still checks the function's policy: a statement allowing principal `*` to perform `lambda:InvokeFunctionUrl`, with the condition `lambda:FunctionUrlAuthType = NONE`. This is the step people forget: the URL exists, auth is "off", yet visitors get `403 Forbidden`. (AWS now additionally wants `lambda:InvokeFunction` with `lambda:InvokedViaFunctionUrl = true` for URLs created after late 2025; the console adds both.)
3. **CORS.** Browsers refuse cross-origin calls unless the URL answers with the right headers. A wildcard (`*`) makes every web page able to call your endpoint on behalf of its visitors; listing the single sign-up origin is correct. The checker verifies that this restriction survived your change.

**Why the checker looks at all three plus a real request:** an anonymous `curl` proves the authentication path, the policy and the config prove it is *intentionally* public, restricted and that the sibling `invite-admin` was not opened up by a careless shell loop.

**Floci note:** the emulator serves function URLs without authentication regardless of `AuthType`, so the checker reads the configuration and policy for those parts and uses the request to prove the endpoint itself works.

**In real life**
- A public URL is an unauthenticated entry point: validate input in the function, set reserved concurrency to cap abuse, and consider AWS WAF via CloudFront in front.
- Prefer `AWS_IAM` plus a signing proxy, or API Gateway with an authoriser, for anything not meant for the whole internet.
- The payload format is the same as API Gateway HTTP APIs v2, with `requestContext.http.method`, `rawPath` and a string `body`.

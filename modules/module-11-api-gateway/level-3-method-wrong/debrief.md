# Debrief: a resource is not a method

A resource (`/tickets`) is only a path. Every HTTP verb you want to serve is its own **method** object, with its own authorization, request validation, integration and responses. Calling a verb that has not been configured returns HTTP 403 `Missing Authentication Token` on real API Gateway (not 405, which people expect), because API Gateway treats "unknown route" and "route that requires a token" the same way to avoid disclosing which routes exist.

Design points:
- `put-method` defines the client-facing contract. `put-integration` defines what happens behind it. For Lambda the integration verb is always POST, whatever the client verb.
- You can wire different verbs to different functions (reads and writes scale and fail separately, and need different IAM permissions) or use `ANY` with a single function that routes internally. The first is easier to secure; the second is easier to deploy.
- Lambda proxy integration passes the HTTP body as a string in `event.body`. The function (not API Gateway) must parse it and decide on 400 vs 201. To make API Gateway reject malformed bodies earlier, attach a model and a request validator to the method.
- A `put-method` call on an existing method replaces it and drops its integration, so use `update-method` for small edits.
- CORS preflight needs its own OPTIONS method; a JSON POST from a browser will not work until you add it (see the CORS mission).

Remember to redeploy: method changes are invisible to clients until a new deployment is attached to the stage.

# Debrief: a REST API is five objects, not one

`create-rest-api` gives you an empty shell with a single root resource `/`. To serve a request you must build the whole chain:

1. **Resource**: a path segment (`/status`) under a parent resource.
2. **Method**: an HTTP verb on that resource, with its authorization setting (`NONE`, `AWS_IAM`, custom authorizer...).
3. **Integration**: what API Gateway does with the request. For `AWS_PROXY` it forwards the whole HTTP request to Lambda as an event and expects `{statusCode, headers, body}` back. The integration's own method is always `POST`, because that is how Lambda is invoked, regardless of the client's verb.
4. **Deployment**: an immutable snapshot of the API configuration. Editing resources does not change what clients see until you deploy again (on real AWS).
5. **Stage**: a named pointer to a deployment (`live`, `prod`...) that becomes part of the URL: `https://{api-id}.execute-api.{region}.amazonaws.com/{stage}/status`. Locally you reach it at `$AWS_ENDPOINT_URL/restapis/{api-id}/{stage}/_user_request_/status`.

Real-world tips:
- Infrastructure-as-code tools create these in dependency order. A half-applied stack leaves pieces behind, so after a failed apply list what exists (`get-rest-apis`, `get-resources`, `get-stages`).
- The Lambda function also needs a resource policy that lets `apigateway.amazonaws.com` invoke it (`lambda add-permission`, scoped with `--source-arn` to this API). Real API Gateway answers 500 until it exists. The local emulator is lenient here, so do not let a working local test fool you.
- Proxy integration pushes responsibility to your code: if the function returns something that is not the proxy format, real API Gateway answers 502.

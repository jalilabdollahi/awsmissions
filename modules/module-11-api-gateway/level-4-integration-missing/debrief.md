# Debrief: the method is the front door, the integration is the room behind it

A REST API method has four stages, each configured separately:

1. **Method request**: what the client may send (auth, required parameters, validators).
2. **Integration request**: how API Gateway calls the backend (type, URI, templates).
3. **Integration response**: how the backend answer is mapped.
4. **Method response**: what the client sees.

`put-method` configures only stage 1. Without `put-integration` the method accepts requests and has nowhere to send them. Real API Gateway reports that as `500 Internal server error` ("Execution failed due to configuration error: No integration defined for method"), which looks like a backend crash and is really a missing configuration.

Integration types worth knowing:
- `AWS_PROXY`: Lambda proxy. The request becomes a JSON event (`path`, `queryStringParameters`, `headers`, `body`...) and the function returns `{statusCode, headers, body}`. Simplest, and the default recommendation.
- `AWS`: non-proxy. You write mapping templates for request and response, and gain validation and transformation without code.
- `HTTP_PROXY` / `HTTP`: forward to a public HTTP endpoint.
- `MOCK`: answer from API Gateway itself, ideal for CORS preflight and stubs.

Tips:
- `get-method` shows `methodIntegration`; if it is absent you have found the problem in seconds.
- A fresh method that was created by console clicks and never finished is the usual cause. IaC avoids half-built methods.
- Always make a post-deploy smoke test that calls each route once.

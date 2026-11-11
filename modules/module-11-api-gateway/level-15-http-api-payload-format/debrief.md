# Debrief: same name, different event

HTTP APIs can hand a Lambda function one of two JSON shapes, selected by the integration's `PayloadFormatVersion`:

| | 1.0 (REST API compatible) | 2.0 (HTTP API native) |
|---|---|---|
| Method | `httpMethod` | `requestContext.http.method` |
| Path | `path`, `resource` | `rawPath`, `routeKey` |
| Query string | `queryStringParameters` plus `multiValueQueryStringParameters` | `queryStringParameters` (comma-joined), `rawQueryString` |
| Cookies | inside `headers` | separate `cookies` array |
| Headers | `headers` and `multiValueHeaders` | `headers` (lower-cased) |
| Response | must be `{statusCode, headers, body}` | may be any JSON, wrapped automatically as a 200 with a JSON body |

A function written for one version and wired to the other crashes at the first missing key, or worse, silently reads `None` and produces garbage. The 500 gives no hint; the cause only shows in the Lambda logs (`KeyError: 'http'`).

Practical advice:
- Choose 2.0 for new code (smaller event, auto-formatted responses); keep 1.0 when migrating an existing REST API function unchanged.
- Return an explicit `statusCode` anyway when you need anything but 200, since the automatic wrapper always answers 200 with the returned JSON.
- Pin the version in IaC; console wizards and older templates default differently, which is how teams end up with a function and an API that disagree.
- Write a tiny contract test: invoke the function with a recorded event of the version the API is configured for, as part of CI.
- Lambda authorizers on HTTP APIs have their own payload version setting, which must also match what the authorizer function expects (see the authorizer mission).

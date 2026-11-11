# Debrief: CORS is the browser enforcing a conversation between two origins

`curl` does not care which site called it; browsers do. When JavaScript from `https://app.zestlist.example` calls another origin with a non-simple request (custom header such as Authorization, JSON content type, or any verb besides GET/HEAD/POST with simple types), the browser first sends a **preflight**: `OPTIONS /tasks` with `Origin`, `Access-Control-Request-Method` and `Access-Control-Request-Headers`. Only if the answer lists the origin, method and headers does it send the real request, and it then checks `Access-Control-Allow-Origin` on that response as well. Miss either step and the call is blocked in the browser, while the API itself is perfectly healthy.

Where CORS lives in API Gateway:
- **REST API, non-proxy**: you configure an OPTIONS method (usually MOCK) plus method response and integration response header mappings, for the preflight and for every real method.
- **REST API, Lambda proxy**: API Gateway adds nothing; your function must return the `Access-Control-Allow-*` headers itself for real requests (the OPTIONS method is still needed, or answered by the same function).
- **HTTP API (v2)**: a single `CorsConfiguration` on the API does it all.

The single quotes matter: in `responseParameters` a value like `'GET,POST'` is a literal; without the quotes API Gateway interprets it as a reference to another header or mapping expression, and the header silently disappears.

Security points:
- `Access-Control-Allow-Origin: *` is not permitted together with credentials (cookies, Authorization from `credentials: "include"`). The browser rejects it. Return the specific origin, ideally by checking against an allow-list and echoing the match (with `Vary: Origin`).
- CORS is not authentication. It only tells browsers what pages may read; anyone can still call the API with curl. Keep real authorization on the methods.
- Errors from API Gateway itself (401, 403, 429, 5xx) do not have your CORS headers unless you also configure Gateway Responses, which is why browsers report an opaque "CORS error" for what is really a 403.

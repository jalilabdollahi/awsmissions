# Debrief: a 500 can be a contract mismatch, not a crash

An HTTP API Lambda authorizer can speak two dialects, chosen on the authorizer object, not in your function:

| | IAM policy response | Simple response |
|---|---|---|
| Returned by the function | `{"principalId", "policyDocument": {...}, "context": {...}}` | `{"isAuthorized": true, "context": {...}}` |
| Needs `EnableSimpleResponses` | no | **yes** |
| Payload format | 1.0 or 2.0 | 2.0 only |
| Decision | `Allow`/`Deny` on the method ARN | a boolean |

If the function returns one dialect while the authorizer is configured for the other, API Gateway cannot interpret the result and answers `500 Internal Server Error` for every request, valid key or not. The authorizer code ran and returned what its author intended, which is why this is so confusing to debug. The problem is configuration drift between the function and the API.

Behaviour to remember:
- With simple responses a missing identity source gives **401** and `isAuthorized: false` gives **403**, the same split as on REST APIs.
- The `context` object is exposed to the integration as `requestContext.authorizer.lambda.<key>` in payload 2.0 (REST APIs use `requestContext.authorizer.<key>`), which is how your function learns who called.
- Authorizer responses can be cached by identity source (`AuthorizerResultTtlInSeconds`); with caching on, a revoked key can keep working for its TTL.
- Simple responses cannot grant access per route: the decision is one boolean for the whole cached identity, so avoid combining many routes with different permissions behind one cached authorizer unless the function checks the route.

Tip: whenever an authorizer "works" in unit tests but fails in the gateway, compare the exact response format and payload version in the docs, then test the authorizer through the API, not by calling the function alone.

# Debrief: keys identify, plans authorize

Three objects are involved, and all three must line up:

1. **API key**: an opaque identifier (the value goes into the `x-api-key` header). It carries no permissions by itself.
2. **Usage plan**: lists which **API stages** it covers, and the **throttle** (steady rate and burst) and **quota** (requests per day, week or month) that apply to the keys inside it.
3. **Method setting** `apiKeyRequired: true`, which makes API Gateway demand a key for that method.

A request is accepted only if the key is valid **and** belongs to a usage plan that covers the stage being called. Otherwise the answer is a flat `403 {"message":"Forbidden"}`, with nothing to tell you which of the pieces is missing. That is why "valid key, still forbidden" almost always means "key not in a plan" or "plan not attached to this stage".

Operational notes:
- A key may belong to several plans, but only one per API stage, which is how you model free vs paid tiers: same API, different plans, different keys.
- Plans are the unit for monetisation and fair use: a quota exhausted gives `429 Limit Exceeded`; throttling gives `429 Too Many Requests`.
- API keys are for **identification and metering**, not security. They travel in clear headers and cannot be scoped to routes. Pair them with an authorizer or IAM auth for real authentication.
- Stage-level and method-level throttling (see the throttling mission) apply in addition; the strictest limit wins.
- Treat the key value like a password in logs and tickets: `get-api-keys` only returns it with `--include-values`.
- The local emulator enforces the key-to-plan linkage but does not count requests, so quota and rate are verified by inspecting the plan.

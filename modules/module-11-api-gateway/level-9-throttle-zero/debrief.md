# Debrief: throttling is a token bucket, and zero means zero

API Gateway throttles with a **token bucket** per account, stage and method:
- **Rate**: tokens added per second (steady-state requests per second).
- **Burst**: bucket size, i.e. how many requests can arrive at once before the bucket is empty.

When the bucket is empty clients get HTTP 429 `Too Many Requests`. A rate and burst of 0 means an empty bucket that never refills, so every call is rejected. "No limit" is not a value you can set per stage; you simply stay under the account-level quota (10,000 rps / 5,000 burst by default in most regions).

Layers of throttling, from most specific to least:
1. **Per-method settings** on the stage (`/checkout/POST`), as in this mission.
2. **Stage default** (`*/*`).
3. **Usage plans** (per API key, and see the API key mission), which also support quotas per day or month.
4. **Account-level** limits for the whole region.

The strictest applicable limit wins. Use method-level overrides to protect fragile or expensive backends (payments, search, PDF rendering) and keep the default generous for cheap reads.

Practical tips:
- Clients should retry 429 with exponential backoff and jitter. The `Retry-After` header is not provided by API Gateway, so build that into the client.
- Throttling protects your backend; it does not stop abuse. Combine with AWS WAF rate-based rules for per-IP limits.
- Method keys escape slashes as `~1` in patch paths: `/~1checkout/POST/throttling/rateLimit`.
- The emulator stores these settings but does not count requests, so only a stage inspection shows the problem locally. On real AWS you would see the `4XXError`/`Count` metrics spike and 429s in the access logs.

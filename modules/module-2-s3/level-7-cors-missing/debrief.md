# Debrief: CORS is the bucket telling browsers who may talk to it

Browsers enforce the same-origin policy. When JavaScript on `https://dashboard.tidewater.example` calls another origin (the S3 endpoint) with a non-simple request, the browser first sends a **preflight**: an `OPTIONS` request carrying `Origin`, `Access-Control-Request-Method` and `Access-Control-Request-Headers`. S3 answers from the bucket's CORS rules. No matching rule means no `Access-Control-Allow-Origin` header, and the browser drops the real request.

**The four parts of a rule**
- `AllowedOrigins`: exact origins (scheme + host + port); one `*` wildcard is allowed per entry.
- `AllowedMethods`: only `GET`, `PUT`, `POST`, `DELETE`, `HEAD`.
- `AllowedHeaders`: request headers the page may send, such as `content-type` or `x-amz-meta-*`.
- `ExposeHeaders`: response headers JavaScript may read. Without `ETag` here, `response.headers.get("ETag")` returns `null` even though the header is on the wire.

**Why it worked from curl**: CORS is enforced by browsers, not by S3. It is not an access control mechanism. Anyone with credentials or a presigned URL can still call S3 directly.

**In real life**
- Browser-side uploads with presigned URLs are the classic CORS consumer. Keep `AllowedMethods` to what the page truly sends.
- Avoid `AllowedOrigins: ["*"]` on buckets that serve authenticated content.
- A change to CORS can take a minute to propagate on real S3 and browsers cache preflight answers for `MaxAgeSeconds`.

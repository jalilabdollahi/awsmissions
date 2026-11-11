# Debrief: the website endpoint is a different front door

An S3 bucket answers on two kinds of endpoint:

| | REST endpoint | Website endpoint |
|---|---|---|
| Host | `bucket.s3.region.amazonaws.com` | `bucket.s3-website-region.amazonaws.com` |
| `/` or `/folder/` | a bucket listing | the index document |
| Errors | XML | your HTML error document, with the real status code |
| Authentication | signed requests | anonymous only |
| HTTPS | yes | **no** (HTTP only) |

Website behaviour exists only if the bucket has a website configuration. The `IndexDocument.Suffix` is appended to every request ending in `/` (so one setting serves every folder), and the `ErrorDocument` is returned for 4xx errors such as a missing key.

**Gotchas**
- The website endpoint reads objects as an *anonymous* visitor. On real AWS the objects must therefore be publicly readable (a bucket policy for the site files), which also means Block Public Access has to allow it.
- No HTTPS: put CloudFront in front for TLS and a custom domain.
- A stale `error.html` is exactly the sort of leftover that makes a launch embarrassing; the configuration, not the file name, decides which page is used.

**In real life**
- Prefer CloudFront + Origin Access Control with a private bucket for production sites; use S3 website hosting for simple or internal use.
- Use `RoutingRules` or `RedirectAllRequestsTo` for redirects instead of keeping stub HTML files.

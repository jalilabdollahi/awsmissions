# Debrief: origins match as exact strings, and one PUT replaces everything

**Origin matching.** The browser sends `Origin: https://admin.brightcart.example`: scheme, host and optional port, never a path or trailing slash. S3 compares it to each `AllowedOrigins` entry literally (a single `*` wildcard per entry is the only pattern). So `https://admin.brightcart.example/`, `http://admin...` and `admin.brightcart.example` are all different origins from the browser's point of view.

**Per-app rules.** Giving each app its own rule keeps privileges separate: the storefront can only read, the admin app can write. Merging them into one rule with `*` would make the public storefront origin able to delete media.

**`put-bucket-cors` is a full replace.** Sending only the admin rule would have silently removed the storefront rule. Always `get-bucket-cors`, edit, and write the whole document back.

**In real life**
- `https://*.brightcart.example` is handy for many subdomains, but remember it also matches `https://anything.brightcart.example`, including forgotten staging hosts.
- Test CORS with `curl -X OPTIONS` and the `Origin` / `Access-Control-Request-Method` headers before blaming the frontend.
- CORS never replaces authentication. It only tells the browser whether page scripts may read the response.

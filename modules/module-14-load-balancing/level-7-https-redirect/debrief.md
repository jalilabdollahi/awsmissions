# Debrief: redirects are rules, with placeholders

A `redirect` action answers the client itself; no target group is involved. `RedirectConfig` can rewrite Protocol, Port, Host, Path and Query. Any part you leave out keeps the original value, and the placeholders `#{protocol}`, `#{host}`, `#{port}`, `#{path}` and `#{query}` let you build a target from pieces of the request. The AWS console's "HTTP to HTTPS" template uses exactly this configuration with `HTTP_301`.

**What was wrong here**
- **302 vs 301.** A 302 tells clients "move for now". Browsers re-ask HTTP every time, and search engines keep the HTTP URL. 301 is cached and transfers ranking. Prefer 301 once you are sure, and remember that browsers cache 301 aggressively, so test with 302 first when you are unsure.
- **Hard-coded path.** `Path: "/"` sends every request to the home page. Keep `/#{path}` (or omit Path) to preserve it. Query defaults to the original; `#{query}` makes the intent explicit.
- **Non-standard port.** Corporate proxies and firewalls often allow 443 only. 443 is also implied when the browser sees `https://` with no port.

**Practical notes**
- The redirect only helps when something listens on 443. Create an HTTPS listener with an ACM certificate and the right target group, and consider a security-header policy plus HSTS in the application.
- Use `curl -I` on the ALB to inspect `Location`; follow redirects with `-L` only after you have looked at the first response.
- Do the redirect at the load balancer, not in every app: one place to configure, no extra hop to your servers.

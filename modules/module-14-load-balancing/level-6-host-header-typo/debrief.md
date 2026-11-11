# Debrief: host-based routing is exact string matching

A `host-header` condition compares the request's `Host` header to each value. It is case-insensitive, and `*` and `?` wildcards are allowed (`*.helixpay.example`), but beyond that it is literal: `exmaple` is simply a different host. Nothing validates that the name exists in DNS or that it resolves to this ALB. A rule with a typo is accepted, and it is silent: the listener falls through to the next rule and the default action, which happily answers with another site.

That is why the symptom was "portal works, app shows the marketing page". Half of the values matched, the other half fell through.

**Notes for real life**
- Several conditions in one rule are ANDed, several values inside one condition are ORed, and rules have per-rule limits on conditions and wildcards, so check the ELB quotas before generating rules with code.
- Keep a request test next to the rule: `curl -H 'Host: app.example.com' http://<alb-dns>/` returns the answer without touching DNS. That is exactly what `probe.sh` did here.
- A wildcard such as `*.helixpay.example` is shorter and survives new subdomains, but it also exposes every future subdomain you point at the ALB, so choose deliberately.
- With HTTPS, put all hostnames on the certificate (or use several certificates on the listener); SNI picks the certificate before the host rule runs.
- `modify-rule` replaces the whole list of conditions, not just one value. Always send the complete list.

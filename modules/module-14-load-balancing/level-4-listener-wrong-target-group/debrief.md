# Debrief: the listener is where routing is decided

A listener has a port and protocol, plus rules. The **default action** is the last rule: it handles every request that no other rule matches, and on a simple site that means every request. `forward` names the target group (or several, with weights). Nothing about the target groups themselves says "this one is production". The *only* link between a load balancer and the fleet that serves it is that ARN.

That makes the listener the place to look when the symptom is "healthy targets, wrong content". Target health says the fleet works, not that it is the right fleet.

**How it happens**
- A release rehearsal or blue/green swap changes the default action and is only half rolled back.
- Two target groups with near-identical names (`portal-prod` vs `portal-prod-v2`) invite copy-paste mistakes with ARNs.

**Good habits**
- Give testers their own path: a second listener port or a host/header rule (`staging.example.com`) pointing at the staging group, so nobody has to repoint the production listener to test.
- `aws elbv2 describe-listeners` and `describe-rules` are cheap; run them in your deploy pipeline and fail when the production listener does not point at the expected target group.
- Tag target groups with `env=prod|staging` and check tags, not names.

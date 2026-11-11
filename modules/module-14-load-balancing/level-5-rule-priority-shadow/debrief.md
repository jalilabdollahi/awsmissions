# Debrief: first match wins, so specific rules go first

An ALB listener checks rules from the **lowest priority number to the highest**; the first rule whose conditions all match decides the request, and the remaining rules are never looked at. The default rule runs last. Priorities must be unique per listener (1 to 50000).

`/api/*` and `/api/admin/*` overlap: every admin URL is also an API URL. With the broad rule first, the narrow rule is dead code. The listener never complains; `describe-rules` shows both rules happily. You find out when somebody tests the path, or from a pen-test report like this one.

**Habits that prevent it**
- Order rules from most specific to least specific, and leave gaps (10, 20, 30...) so you can insert one later without renumbering.
- Whenever you add a rule, test the paths it is supposed to catch *and* a path it is not supposed to catch.
- `set-rule-priorities` changes several priorities in one atomic call, which avoids a window where two rules clash or the wrong one wins.
- Block rules with a `fixed-response` are cheap and fast, but treat them as defence in depth. The real fix for an exposed admin API is authentication in the application, or a WAF web ACL in front of the ALB.
- Wildcards are case-sensitive and `*` matches any run of characters, including slashes, so `/api/*` really does include `/api/admin/anything`.

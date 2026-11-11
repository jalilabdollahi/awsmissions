# Debrief: a stage is where an API actually lives

Configuring resources, methods and integrations edits a *draft*. Nothing is callable until a **deployment** (a frozen snapshot of that draft) is attached to a **stage**. The stage name becomes the first path segment of the invoke URL, so a mobile app hard-coded to `/prod/` finds nothing when only `/dev/` exists. The response is a 404 `Not Found` from API Gateway itself.

What a stage adds:
- **Stage variables**: key/value pairs available to integrations (`${stageVariables.name}`) and to Lambda proxy functions as `event.stageVariables`. They let one API definition behave differently per environment (backend URLs, function aliases, feature flags). They are plain configuration, not secrets.
- **Per-stage settings**: throttling, caching, logging, X-Ray, WAF association, client certificates and canary releases.
- **History**: each `create-deployment` is a new snapshot; a stage can be rolled back by pointing it at an older deployment id (`update-stage --patch-operations op=replace,path=/deploymentId,value=...`).

Release hygiene:
- Treat "deploy to the stage clients use" as an explicit release step, in CI, not as something done by hand from a laptop.
- Use the same API definition for all stages and vary only stage variables. If dev and prod diverge in resources, tests on dev prove nothing.
- Deploy after every configuration change; changes made after the last deployment are invisible to clients on real AWS.
- The emulator is more forgiving: it applies edits immediately, so a change that "works locally" may still need a deployment on AWS.

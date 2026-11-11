# Debrief: a health check is a question, so ask a good one

Every few seconds the load balancer sends an HTTP request to each target (`HealthCheckPath`, on `HealthCheckPort`) and compares the response code with the **matcher** (`200` by default). `HealthyThresholdCount` successes in a row make a target healthy; `UnhealthyThresholdCount` failures make it unhealthy. Traffic only goes to healthy targets.

Terraform and CloudFormation default the path to `/`. Plenty of APIs, workers and internal services return 404 or a redirect there, so the check fails even though the service is fine.

**A subtle detail in this mission:** when *all* targets of a group are unhealthy, an ALB does not stop. It "fails open" and sends traffic to every target anyway. The site kept working, so nobody paged anyone. A red target-health graph is a real alert even when users do not complain yet.

**Good health checks**
- Use a dedicated endpoint (`/healthz`, `/ready`) that is cheap and returns 200 only when the app can serve.
- Keep the matcher narrow. `200-499` turns the check into "something is listening", which hides crashes and misconfiguration behind green dots.
- Decide what the check should include. A check that also queries the database takes every instance out of rotation at once when the database blips. Many teams keep the load balancer check shallow and put deep dependency checks in monitoring.
- `describe-target-health` explains itself: `Target.ResponseCodeMismatch` is exactly this mission, `Target.Timeout` means no answer in time, `Target.FailedHealthChecks` is a connection problem.

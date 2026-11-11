# Debrief: health check timing is a budget

Four numbers define a health check: **interval** (how often), **timeout** (how long to wait for one answer), **healthy threshold** and **unhealthy threshold** (consecutive results needed to flip state). Two rules follow:
- The timeout has to be *shorter* than the interval (the console enforces it, the API rejects violations).
- Time to detect an outage is roughly `interval x unhealthy threshold`, plus up to one timeout. With 30 s x 5 that is two and a half minutes of serving errors before a target is pulled.

`Target.Timeout` means the target accepted the connection (or did not) but no response arrived inside the timeout. It is different from `Target.ResponseCodeMismatch` (wrong status) and `Target.FailedHealthChecks` (connection failed).

**Why a deep check is a trap**
A health endpoint that queries the database or calls other services couples every instance's health to that dependency. When the dependency slows down, *all* targets time out at once and the load balancer has nothing healthy to use. It then fails open and sends traffic to everything anyway, so you get the pain without the protection. The usual pattern is a **shallow** load balancer check (`/livez`: process is up and can accept requests) plus **deep** checks in monitoring and alarms.

**If you must keep a slow check**: raise the timeout above the real response time with margin, raise the interval so checks do not pile up, and watch the detection-time budget. Do not just crank everything to the maximum: a 60 s timeout with a 300 s interval is a check that notices outages when the postmortem is already written.

# Debrief: a health check is a contract

A load balancer decides who gets traffic by sending a request every few seconds to `protocol://target:port<path>` and comparing the HTTP status with the matcher (default `200`). Three settings must agree with the application: port, path, and accepted codes. The reason in `describe-target-health` tells you which one disagrees:

- `Target.ResponseCodeMismatch`: reached the app, got the wrong status (this level: 404 on a path that doesn't exist).
- `Target.Timeout` / `Target.FailedHealthChecks`: nothing answered (wrong port, security group, app down).

The temptation is to widen the matcher to `200-499` or point at `/`. Both turn the green light on and silence the safety net, because `/` can answer 200 while the app's dependencies are broken. A good health endpoint is cheap, unauthenticated and honestly reflects readiness.

Notes on ECS: the service scheduler replaces tasks that the load balancer reports unhealthy, so a wrong health check often shows up as an endless cycle of tasks being started and killed. Use `healthCheckGracePeriodSeconds` on the service for slow starters instead of loosening the check.

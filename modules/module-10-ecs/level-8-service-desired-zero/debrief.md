# Debrief: "ACTIVE" does not mean "has tasks"

An ECS service is a controller with one job: keep `runningCount` equal to `desiredCount`. With `desiredCount: 0` it is perfectly satisfied, its status stays ACTIVE and its events say "has reached a steady state". Nothing flags a problem except the traffic that now has no targets.

Habits that prevent this:
- Treat scale-to-zero as a temporary override and track it (ticket, calendar reminder, or an alarm on `RunningTaskCount < 1` for production services).
- If you use Application Auto Scaling, a `MinCapacity` of 0 lets a policy scale a service to zero on its own; set a sensible minimum for services that must stay up.
- `describe-services` shows `desiredCount`, `runningCount` and `pendingCount` side by side: compare them before digging into logs.
- Keep at least two tasks across two AZs for production services so a deployment or an AZ failure does not remove all capacity.

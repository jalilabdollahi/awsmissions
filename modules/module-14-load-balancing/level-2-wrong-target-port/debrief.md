# Debrief: two places hold a port, and the target's wins

A target group has a **default port**. Each registered target may carry its own **port override**; if it does, the override is what the load balancer uses for both traffic and health checks (when the health check port is `traffic-port`, the default). A target is identified by the pair *(id, port)*, so the same instance can be registered several times on different ports, for example to front several containers on one host.

That is why this failure is confusing. `describe-target-groups` shows a correct port 8080, and the instance is running, yet the target reports `Target.FailedHealthChecks` because the checks go to port 80.

**Diagnosing**
- `describe-target-health` prints `Target.Port`. Compare it with the port the application really listens on.
- `Target.FailedHealthChecks` means the ALB reached out and got the wrong answer or no answer. `Target.Timeout` means no answer in time. `Target.NotInUse` or `Target.InvalidState` point at other problems (for example the target group is not attached to any load balancer).

**Fixing and avoiding it**
- You cannot edit a target: deregister `(id, port)` and register again.
- Let the group's default port apply unless you truly need an override.
- With ECS and Auto Scaling the service registers targets for you, using the container port or the group default, which is another reason to avoid hand registration.

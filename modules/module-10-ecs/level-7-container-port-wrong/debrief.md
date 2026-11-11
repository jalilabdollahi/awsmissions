# Debrief: three ports that must agree

A load-balanced container involves three port settings:

1. The port the **application listens on** (here 3000, from its own config).
2. The **containerPort** in the task definition's `portMappings` and in the service's `loadBalancers` entry: this is the port ECS registers as the target.
3. The target group's **port and health-check port**.

If the ECS side registers 8080, the load balancer dutifully health-checks `ip:8080`, finds nothing listening, and marks the target unhealthy (`Target.FailedHealthChecks`). Nothing is "down": the traffic is simply being sent to the wrong door.

Real-world tips:
- `awsvpc` tasks have their own ENI, so `hostPort` equals `containerPort`; there is no dynamic port mapping as with bridge mode.
- Copy-pasting task definitions between services is a common source of this. Template the port from one variable.
- Use `describe-target-health`: its `Reason` (`FailedHealthChecks`, `ResponseCodeMismatch`, `Timeout`) tells you whether it is the port, the path or a security group.

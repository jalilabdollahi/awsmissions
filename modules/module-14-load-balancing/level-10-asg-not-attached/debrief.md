# Debrief: the group must know the target group

The link between Auto Scaling and Elastic Load Balancing lives on the **group** (`TargetGroupARNs`, or the older `LoadBalancerNames` for classic ELBs). When the group launches an instance it calls RegisterTargets for every listed target group, and when it terminates one it deregisters it first, honouring the deregistration delay so in-flight requests finish.

Registering instance IDs by hand makes the symptom disappear and plants a trap. The next scale-out, replacement, or instance refresh produces an instance nobody registered, silently shrinking capacity until the ALB is serving from one overloaded node, or none.

**Diagnosing "instances are fine but the ALB has no targets"**
1. `describe-auto-scaling-groups`: is `TargetGroupARNs` empty?
2. `describe-target-health`: are the group's instance IDs listed at all?
3. `describe-scaling-activities`: did the launch or an attach step fail?

**More to know**
- `attach-load-balancer-target-groups` and `detach-load-balancer-target-groups` change this at any time without recreating the group. Detaching starts a deregistration, which is the polite way to take a fleet out of service.
- Use `HealthCheckType: ELB` (with a grace period longer than boot time) so the group replaces instances that the load balancer thinks are unhealthy, not only ones EC2 says are dead. This group still uses `EC2`; that is a good follow-up improvement.
- In CloudFormation or Terraform, `TargetGroupARNs` on the group is the one line that prevents this entire class of outage.

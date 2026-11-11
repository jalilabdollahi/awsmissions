# Debrief: open the port the app uses, to the callers that need it

A security group rule is `protocol + port range + source`. The most common mistake is guessing the port. The authoritative answer comes from the application's own configuration (here a Parameter Store entry; in real life the container `PORT`, the target group's port, or `ss -ltnp` on the host).

Using a **source security group** instead of a CIDR is the idiomatic way to wire tiers together: the rule keeps working when the load balancer's IPs change or you add nodes, and it can never be reached from outside the ALB.

Tips:
- Unused rules are attack surface and confuse the next debugger. Remove them when you correct a port.
- Load balancer health checks use the target group's health-check port, which may differ from the traffic port; that port needs a rule too.
- `aws ec2 describe-security-group-rules --filters Name=group-id,Values=<id>` shows each rule with an id you can modify individually.

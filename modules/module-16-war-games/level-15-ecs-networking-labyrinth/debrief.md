# Debrief: INC-5561, the unreachable service

## Root causes
| # | Layer | Fault |
|---|---|---|
| 1 | ECS service | Copied network configuration: public subnet and public IPs, contradicting the "private only" rule |
| 2 | Route table | The private subnet had no default route, so tasks could not reach the internet (no image pulls, no partner APIs) |
| 3 | Security group egress | The allow-all egress rule was deleted and only HTTP re-added, so outbound HTTPS was blocked |
| 4 | Security group ingress | The rule letting the load balancer reach port 8080 was lost when the group was recreated |

## Timeline
- Migration night: VPC, subnets and groups created partly by hand.
- 06:00: ECS shows the service healthy ("RUNNING 1/1"), which only means containers are up.
- 09:20: load balancer health checks fail; engineers also see image-pull timeouts on new deployments.

## Why this combination is classic
"Running" in ECS says nothing about reachability. A packet needs four things to be true at once: the task in the right subnet, a route out (a NAT gateway for private subnets), a security group that allows the outbound call, and a security group that allows the inbound call from the caller. Each of these is configured in a different place, and a fault in any one looks the same from outside: timeouts.

Referencing the load balancer's security group in the inbound rule (instead of an IP range) keeps working when the load balancer's IPs change and expresses the intent: "only that tier may talk to this one".

## Lessons
- Verify reachability from both ends: VPC Reachability Analyzer (or a probe task) catches what config reading cannot.
- Do not "fix" a private subnet with an internet gateway route, and do not open an app port to the world. Both fix the symptom and remove the security programme's benefit.
- Recreate security groups from code; hand-recreated groups lose rules.
- NAT gateways cost money per hour and per GB. Use VPC endpoints for ECR, S3 and CloudWatch Logs to cut both cost and exposure.

# Debrief: a load balancer is only a front door

An Application Load Balancer owns no servers. A **listener** accepts connections, a rule decides which **target group** gets the request, and the target group holds the **targets** that actually answer. If any link in that chain is missing, you see the symptom here: HTTP 503 "Service Unavailable". The ALB is healthy; it simply has no healthy target to pick.

**What to check, in order**
1. `describe-listeners`: is there a listener, and which target group does its default action forward to?
2. `describe-target-health`: are there targets, and what state are they in (`initial`, `healthy`, `unhealthy`, `draining`, `unused`)?
3. Only then look at the instances themselves.

**Why it happens in real life**
- Infrastructure code created the target group but the step that registers instances (or attaches an Auto Scaling group) failed or was never written.
- Someone deregistered instances "temporarily" during a deploy and forgot to put them back.

**Tips**
- A new target stays in `initial` until it passes the configured number of health checks. Do not conclude it is broken after two seconds.
- For fleets, do not register instances by hand. Attach the target group to an Auto Scaling group so every new instance registers itself (you will do exactly that in a later mission).
- A CloudWatch alarm on `HealthyHostCount < 1` for each target group catches this failure before your customers do.

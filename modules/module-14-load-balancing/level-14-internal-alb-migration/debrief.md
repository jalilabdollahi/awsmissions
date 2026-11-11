# Debrief: some load balancer properties are forever

**Scheme** decides where the load balancer's nodes live and what addresses they get. An *internet-facing* load balancer has public IPs and public DNS resolution and must sit in subnets that route to an internet gateway. An *internal* one only has private IPs and is meant for traffic inside the VPC (or peered networks, VPN and Direct Connect). The scheme (and the type, application vs network) cannot be changed after creation.

That makes "just recreate it" a real operation, and it is worth doing in a repeatable way:
- **Read before you delete.** `describe-listeners` and `describe-rules` hold the whole routing table. Export them (`--output json`) first. Rule priorities, conditions *and* the exact fixed-response bodies matter; here the `/status` rule was number one, ahead of the host rule.
- **Target groups, certificates and security groups are independent objects** and survive the load balancer, so reuse them. A target group can be attached to several load balancers at the same time, which allows a blue/green swap of the front door itself: build the new one, test it by its DNS name, then flip DNS.
- **DNS is the cutover.** Real clients use a Route 53 alias or CNAME to the load balancer's DNS name. Lower the TTL beforehand, switch the record, keep the old load balancer until the TTL has expired, then delete it. Here the exercise removes the old one straight away, which is only safe because nobody resolved it yet.

**Availability Zones**: an ALB needs two subnets in two zones at least; add every zone your targets run in, because cross-zone is on by default for ALBs, but a zone without an ALB node has no front door of its own for clients that resolve to it. Add the zones before you need them (subnets can be added later, but removing a zone takes traffic out of it).

**Prevent it**: define the scheme in your IaC and review it like a firewall rule. In CloudFormation and Terraform a scheme change forces replacement, so a "harmless" edit can swap your front door.

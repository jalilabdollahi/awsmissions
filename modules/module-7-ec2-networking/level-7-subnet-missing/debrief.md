# Debrief: a subnet lives in exactly one availability zone

A VPC spans a whole region, but a subnet is pinned to a single AZ. High availability therefore comes from creating one subnet per AZ and spreading resources across them. An Application Load Balancer enforces this: it refuses to be created unless you give it subnets in at least two AZs.

Things to remember:
- Subnet CIDRs must sit inside the VPC range and must not overlap one another. AWS reserves 5 addresses per subnet (network, router, DNS, future use, broadcast), so a /28 holds only 11 usable IPs.
- A subnet is only "public" because of its *route table* (a route to an internet gateway), not because of its name or tags. The tag here is just a convention that tooling can filter on.
- Size subnets for growth; they cannot be resized. Container platforms like EKS and ECS awsvpc mode burn many IPs.

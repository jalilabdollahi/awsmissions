# Debrief: DNS that follows your tasks

`awsvpc` tasks get a fresh private IP every time they start, so clients need a name that tracks them. Cloud Map provides it:

1. A **private DNS namespace** (`shop.local`) creates a Route 53 private hosted zone attached to your VPC.
2. A **Cloud Map service** (`inventory`) defines the record type and TTL. For awsvpc tasks use `A` records (`SRV` is needed for bridge/host networking with dynamic ports). `MULTIVALUE` returns all healthy IPs.
3. The **ECS service** carries a `serviceRegistries` entry. From then on ECS registers each task's IP when it starts and deregisters it when it stops.

Clients then resolve `inventory.shop.local` from inside the VPC. The VPC needs DNS support and hostnames enabled for the private zone to resolve.

Real-world tips:
- Keep the TTL low (10-30 s) so clients notice replaced tasks quickly, and make clients re-resolve instead of caching forever.
- Registration happens only for tasks the *service* launches, not for standalone `run-task`.
- For load-balanced traffic, an ALB with a stable DNS name is usually better than DNS round-robin; Cloud Map shines for east-west service-to-service calls and for non-HTTP protocols.

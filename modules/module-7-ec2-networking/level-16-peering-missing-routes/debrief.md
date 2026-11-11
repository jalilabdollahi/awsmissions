# Debrief: peering is a handshake plus two routes

A VPC peering connection is a private link between two VPCs. Creating it does not make it usable:

1. **Accept**: the request sits in `pending-acceptance` until the accepter side approves it (same account here, often another team or account in real life).
2. **Route both ways**: peering adds no routes automatically. The sender needs a route to the peer's CIDR, and the receiver needs the return route; without it the packet arrives but the reply is lost, which looks like a timeout.
3. **Allow**: security groups (and NACLs) on the destination must permit the source range. Within one region you can reference the peer's security group instead of a CIDR.

Rules worth remembering: peering is **non-transitive** (A-B and B-C does not give A-C; use a Transit Gateway) and CIDRs must not overlap, which is the reason to plan address space early. Routing `0.0.0.0/0` into a peering is never right; it would blackhole internet traffic.

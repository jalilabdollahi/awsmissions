# Debrief: egress is the half people forget

Every new security group ships with one allow-all outbound rule. Delete it and the group becomes deny-by-default in both directions. Because groups are stateful, replies to inbound connections still get out, but anything the instance *starts* needs an egress rule.

This is the opposite failure from an ingress mistake and it looks different: DNS lookups, package installs, API calls and database connects all hang at once.

Real-world tips:
- Hardened egress is good practice for databases and workers. Enumerate flows: DNS (UDP/TCP 53 to the VPC resolver), HTTPS to AWS endpoints, the database port.
- Referencing the database *security group* as the destination follows the DB if it moves; a CIDR does not.
- Remember return paths still cross the other side's rules: the DB group needs the matching ingress rule (already present here).
- VPC endpoints let a locked-down worker reach AWS APIs without a route to the internet at all.

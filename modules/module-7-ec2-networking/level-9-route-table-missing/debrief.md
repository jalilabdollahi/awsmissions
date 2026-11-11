# Debrief: the main route table is a shared default

Every subnet is associated with exactly one route table. If you do not associate one explicitly, AWS silently uses the VPC's main route table. That makes the main table a dangerous place for an internet route: add a default route there and every present and future subnet that lacks its own table turns public, including the database subnet you meant to protect.

The safe pattern is:
- Keep the main table minimal (local routes only), so anything forgotten defaults to private.
- Create explicit route tables for each purpose (public, private-with-NAT, isolated) and associate them with subnets.
- "Public subnet" is not a setting. It is simply "its route table has a route to an IGW" (plus a public IP on the instance).

Tip: `aws ec2 describe-route-tables --filters Name=association.main,Values=true` shows the main table; review it whenever someone says a subnet is "accidentally public".

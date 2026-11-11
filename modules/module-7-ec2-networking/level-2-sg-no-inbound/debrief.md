# Debrief: security groups start closed

A security group is a stateful allow-list. With no inbound rule there is nothing to match, so traffic is silently dropped (a timeout, not a "connection refused"). That timeout-versus-refused difference is a useful diagnostic: refused means you reached the host and nothing listens; a timeout usually means a firewall (security group, NACL) or a missing route.

Real-world tips:
- Rules are additive across all groups attached to an instance; there is no deny and no ordering.
- Stateful means replies to allowed requests flow back automatically, so you never add a rule for response traffic.
- A shortcut like `--protocol -1 --cidr 0.0.0.0/0` makes the symptom go away and creates an incident later. Open exactly the ports the service uses.
- Put TLS termination in front (ALB, CloudFront) and let the instance accept traffic only from that group; for a public blog the direct 80/443 rule is the simplest starting point.

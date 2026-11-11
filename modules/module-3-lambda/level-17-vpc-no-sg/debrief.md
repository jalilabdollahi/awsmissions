# Debrief: security groups talk about each other

A security group is a stateful firewall attached to network interfaces. For a VPC-enabled function the interface belongs to the Lambda environment, and **the security groups you list are the only firewall identity it has**.

Rule sources come in two kinds:
- **CIDR ranges** (`10.70.0.0/16`, `0.0.0.0/0`): brittle, because addresses change, and Lambda ENIs get new IPs constantly.
- **Security group references** (`UserIdGroupPairs`): "anything wearing group X". This is the right tool for service-to-service access and the reason the warehouse rule survives scaling and IP churn.

So the healthy pattern is: the client (function) gets its own group, and the server's group lists that group as an allowed source on exactly the port needed. Each of the other groups in the story shows a failure mode:
- `reporting-sg`: valid group, but the database does not list it; connection hangs.
- `bastion-admin-sg`: would work for SSH rules but exposes application code to office-network trust.
- Opening 5432 to `0.0.0.0/0` makes the symptom disappear and the security team's week very long.

**Outbound rules** matter too. A new group allows all egress by default; if you tighten egress to specific ports, remember DNS (UDP/TCP 53) and the database port.

**Floci note:** the emulator accepts the empty configuration, so the checker evaluates the configuration against the EC2 security group rules directly.

**In real life**
- Name groups by role (`etl-clients-sg`), never by IP, and describe each rule.
- VPC Reachability Analyzer can prove or disprove a path between an ENI and the database.
- Query a group's references with `aws ec2 describe-security-group-references --group-id <id>` before deleting it.

# Debrief: both ends of a connection need a rule

Security groups are stateful, so a reply never needs its own rule, but a *new* connection is evaluated twice: against the sender's outbound rules and the receiver's inbound rules. Hardening one side without the other is a perfect way to build an outage. Here the task group had its outbound rules removed, and the endpoint group trusted a subnet that no longer exists, so tasks could neither start connections nor would the endpoints have accepted them.

Interface endpoints (PrivateLink) are ENIs in your subnets. Anything that talks to them must reach them on 443 and the endpoint's own security group decides who may. An isolated VPC with endpoints for `ecr.api`, `ecr.dkr`, `logs` and `secretsmanager` (plus an S3 gateway endpoint for image layers) is the classic Fargate design with no NAT and no internet path.

Real-world tips:
- Reference security groups, not CIDRs, between tiers: the rule survives subnet and IP changes.
- Stale CIDR rules are a smell: they are invisible until the address space is reused by something else.
- When a Fargate task in an isolated VPC fails to start, think in this order: endpoint exists for each service, endpoint SG ingress, task SG egress, endpoint private DNS enabled, S3 gateway endpoint for ECR layers.

# Debrief: NAT is a one-way door

A private subnet has no route to an internet gateway, so its resources have no path out and no one has a path in. A **NAT gateway** adds the missing outbound path: tasks send traffic to it, it forwards from its Elastic IP, and replies are translated back. Nothing on the internet can start a connection to the tasks.

The details that decide whether it works:
- The NAT gateway lives in a **public** subnet (one whose route table has an IGW route) and needs an Elastic IP. A NAT in a private subnet is a dead end.
- The private route table then sends `0.0.0.0/0` to the NAT gateway.
- Fargate tasks in private subnets need egress to pull images (ECR/Docker Hub), fetch secrets and ship logs. Without NAT or VPC endpoints they fail at start-up with `CannotPullContainerError` or `ResourceInitializationError`.

Real-world tips:
- A NAT gateway is zonal and costs per hour plus per GB. Use one per AZ for resilience, or fewer for non-production.
- For AWS services, gateway endpoints (S3, DynamoDB) and interface endpoints (ECR, Logs, Secrets Manager) avoid NAT traffic charges and keep the data on the AWS network.
- Do not "just give the task a public IP" in a private design; the subnet's route table, not the task flag, decides reachability.

# Debrief: a VPC-enabled function lives in your subnets

By default a Lambda function runs in an AWS-managed network with internet access and no way into your private resources. Adding a `VpcConfig` makes Lambda create elastic network interfaces (ENIs) in **your subnets**, with **your security groups**, so the function behaves like any other host in that VPC.

What must hold:
- **Subnets and security groups from the same VPC.** Lambda rejects mixed VPCs.
- **At least two subnets in different availability zones** for resilience. Lambda spreads environments across the zones you give it; one zone means one point of failure.
- **Private subnets.** Lambda ENIs never get public IPs, even when placed in a public subnet. A route to an internet gateway therefore doesn't give the function internet access; it only invites confusion. If the function needs the internet, route private subnets through a NAT gateway.
- **`--vpc-config` replaces the whole block**: forgetting `SecurityGroupIds` when updating subnets drops the security group.
- Network paths are a combination of: subnet routes, security group rules (the database's security group allows 5432 from `order-sync-sg`) and network ACLs.

**Floci note:** this emulator accepts any `VpcConfig`, including an empty one, so the checker inspects the configuration and cross-checks it against EC2 (subnet VPCs, zones, route tables) rather than testing a real connection.

**In real life**
- A function in a VPC needs the execution role permission `ec2:CreateNetworkInterface`, `DescribeNetworkInterfaces`, `DeleteNetworkInterface` (the managed policy `AWSLambdaVPCAccessExecutionRole`), or deployment fails.
- Reach AWS services without a NAT by adding VPC endpoints (gateway endpoints for S3/DynamoDB are free).
- Timeouts to a database from Lambda are almost always one of: wrong subnet, wrong security group rule, or no route to the service.

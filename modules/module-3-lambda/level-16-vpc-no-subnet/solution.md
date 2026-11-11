# Solution

The function's VPC configuration has a security group but an empty subnet list, which means it is not attached to any network. It needs private subnets of `orders-vpc` in at least two availability zones.

1. Find the VPC and its subnets (the `Name` tags tell you which is which):

```bash
aws ec2 describe-vpcs --filters Name=tag:Name,Values=orders-vpc --query 'Vpcs[0].VpcId'
aws ec2 describe-subnets --filters Name=vpc-id,Values=<vpc-id> \
  --query 'Subnets[].[SubnetId,AvailabilityZone,Tags[0].Value]' --output table
```

2. A public subnet is one whose route table has a `0.0.0.0/0` route to an `igw-...`. Check the route tables:

```bash
aws ec2 describe-route-tables --filters Name=vpc-id,Values=<vpc-id> \
  --query 'RouteTables[].[RouteTableId,Associations[].SubnetId,Routes[].GatewayId]'
```

Only `orders-edge-a` is routed to the internet gateway; `orders-app-a/b/c` are private.

3. Keep the existing security group and set two or more private subnets in different zones:

```bash
aws lambda update-function-configuration --function-name order-sync \
  --vpc-config SubnetIds=<app-a-id>,<app-b-id>,SecurityGroupIds=<order-sync-sg-id>
```

Note that `--vpc-config` replaces the whole block; include the security group again.

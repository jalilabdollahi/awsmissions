# Solution

A private subnet reaches the internet through a NAT gateway that lives in a public subnet.

```bash
VPC=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=lantern --query 'Vpcs[0].VpcId' --output text)
PUB=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC Name=tag:Name,Values=lantern-public --query 'Subnets[0].SubnetId' --output text)
PRIVRT=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$VPC Name=tag:Name,Values=lantern-private-rt --query 'RouteTables[0].RouteTableId' --output text)

EIP=$(aws ec2 allocate-address --domain vpc --query AllocationId --output text)
NAT=$(aws ec2 create-nat-gateway --subnet-id $PUB --allocation-id $EIP --query NatGateway.NatGatewayId --output text)
aws ec2 create-route --route-table-id $PRIVRT --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT
```

Do not point the private route table at the internet gateway: that would turn the subnet public.

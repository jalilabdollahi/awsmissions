# Solution

The route to `skyline-igw` is fine; the gateway simply was never attached to the VPC, so the route is a dead end.

```bash
VPC=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=skyline-prod --query 'Vpcs[0].VpcId' --output text)
IGW=$(aws ec2 describe-internet-gateways --filters Name=tag:Name,Values=skyline-igw --query 'InternetGateways[0].InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC
```

Attaching `legacy-igw` instead would not help: the route table points at `skyline-igw`.

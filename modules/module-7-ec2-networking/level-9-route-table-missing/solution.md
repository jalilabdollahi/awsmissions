# Solution

Subnets without an explicit association use the VPC's **main** route table. Adding an internet route to the main table would make the db subnet public too, so create a dedicated public table instead.

```bash
VPC=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=harborview-prod --query 'Vpcs[0].VpcId' --output text)
IGW=$(aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=$VPC --query 'InternetGateways[0].InternetGatewayId' --output text)
WEB=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=hv-web --query 'Subnets[0].SubnetId' --output text)
RT=$(aws ec2 create-route-table --vpc-id $VPC --query RouteTable.RouteTableId --output text)
aws ec2 create-route --route-table-id $RT --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW
aws ec2 associate-route-table --route-table-id $RT --subnet-id $WEB
```

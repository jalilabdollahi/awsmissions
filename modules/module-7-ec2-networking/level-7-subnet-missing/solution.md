# Solution

An ALB needs subnets in at least two availability zones, and the VPC has none. Create two, in different zones, with the `Tier=public` tag:

```bash
VPC=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=brightwave-prod --query 'Vpcs[0].VpcId' --output text)
aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.70.1.0/24 --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Tier,Value=public}]'
aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.70.2.0/24 --availability-zone us-east-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Tier,Value=public}]'
```

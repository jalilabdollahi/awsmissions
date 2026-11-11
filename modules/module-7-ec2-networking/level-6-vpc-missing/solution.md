# Solution

The primary CIDR of a VPC is immutable, so the rejected VPC has to be replaced.

```bash
aws ec2 describe-vpcs --query 'Vpcs[].[VpcId,CidrBlock,Tags[0].Value]' --output table
aws ec2 delete-vpc --vpc-id <the rejected meridian-prod>
aws ec2 create-vpc --cidr-block 10.20.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=meridian-prod}]'
aws ec2 modify-vpc-attribute --vpc-id <new vpc> --enable-dns-hostnames
```

Any 10.x block of /16-/20 that avoids 10.0.0.0/16 and 172.31.0.0/16 passes.

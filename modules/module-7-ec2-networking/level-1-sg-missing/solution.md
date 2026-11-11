# Solution

`launch-web.sh` passes `--security-group-ids sg-0a11c0de5afe0001`, a group that was deleted in the cleanup, so `run-instances` fails with `InvalidGroup.NotFound`. A security group belongs to exactly one VPC, so the old `tindle-web` group in the default VPC cannot be used either.

1. Find the VPC and create a group inside it:

```bash
VPC=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=tindle-prod --query 'Vpcs[0].VpcId' --output text)
SG=$(aws ec2 create-security-group --group-name tindle-storefront \
  --description "Tindle storefront HTTPS" --vpc-id $VPC --query GroupId --output text)
```

2. Allow HTTPS from the internet (and nothing else):

```bash
aws ec2 authorize-security-group-ingress --group-id $SG --protocol tcp --port 443 --cidr 0.0.0.0/0
```

3. Put the new group id into `launch-web.sh` and run it: `bash launch-web.sh`.

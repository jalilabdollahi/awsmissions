# Solution

The key pair is injected at first boot, so it cannot be added to an existing instance. Launch a replacement with `--key-name platform-ops` in the same subnet and group, then terminate the keyless host.

```bash
OLD=$(aws ec2 describe-instances --filters Name=tag:Name,Values=atlas-bastion --query 'Reservations[0].Instances[0].InstanceId' --output text)
SUBNET=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=atlas-public --query 'Subnets[0].SubnetId' --output text)
SG=$(aws ec2 describe-security-groups --filters Name=group-name,Values=atlas-bastion-sg --query 'SecurityGroups[0].GroupId' --output text)
aws ec2 run-instances --image-id ami-alpine --instance-type t3.micro --subnet-id $SUBNET --security-group-ids $SG \
  --key-name platform-ops --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=atlas-bastion}]'
aws ec2 terminate-instances --instance-ids $OLD
```

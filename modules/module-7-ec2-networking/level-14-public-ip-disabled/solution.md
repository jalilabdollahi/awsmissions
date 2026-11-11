# Solution

Launching into a subnet with `MapPublicIpOnLaunch=false` gives the instance no public address, and flipping that subnet flag later does not retrofit running instances. An Elastic IP fixes both: it works on a running instance, and it stays yours until released.

```bash
IID=$(aws ec2 describe-instances --filters Name=tag:Name,Values=orbit-status --query 'Reservations[0].Instances[0].InstanceId' --output text)
ALLOC=$(aws ec2 allocate-address --domain vpc --query AllocationId --output text)
aws ec2 associate-address --instance-id $IID --allocation-id $ALLOC
```

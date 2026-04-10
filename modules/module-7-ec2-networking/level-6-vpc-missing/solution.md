# Solution

```bash
# Edit the local mission artifact first
$EDITOR network.json
# This edited file applies to: VpcId vpc-12345678

# Then apply the fix
aws ec2 create-vpc --cidr-block 10.0.0.0/16
```

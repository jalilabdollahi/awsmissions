# Solution

```bash
# Edit the local mission artifact first
$EDITOR network.json
# This edited file applies to: DefaultRoute igw-12345678

# Then apply the fix
aws ec2 create-route --route-table-id rtb-12345678 --destination-cidr-block 0.0.0.0/0 --gateway-id igw-12345678
```

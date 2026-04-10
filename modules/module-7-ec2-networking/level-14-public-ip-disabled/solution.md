# Solution

```bash
# Edit the local mission artifact first
$EDITOR network.json
# This edited file applies to: AssociatePublicIpAddress True

# Then apply the fix
aws ec2 modify-subnet-attribute --subnet-id subnet-12345678 --map-public-ip-on-launch
```

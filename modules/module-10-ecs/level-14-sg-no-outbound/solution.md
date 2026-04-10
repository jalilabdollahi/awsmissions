# Solution

```bash
# Edit the local mission artifact first
$EDITOR network.json
# This edited file applies to: egress 0.0.0.0/0

# Then apply the fix
aws ec2 authorize-security-group-egress --group-id sg-12345678 --ip-permissions IpProtocol=-1,IpRanges=[{CidrIp=0.0.0.0/0}]
```

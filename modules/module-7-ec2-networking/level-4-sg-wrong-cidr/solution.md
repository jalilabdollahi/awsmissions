# Solution

```bash
# Edit the local mission artifact first
$EDITOR network.json
# This edited file applies to: CidrIp 0.0.0.0/0

# Then apply the fix
aws ec2 authorize-security-group-ingress --group-id sg-12345678 --protocol tcp --port 80 --cidr 0.0.0.0/0
```

# Solution

```bash
# Edit the local mission artifact first
$EDITOR network.json
# This edited file applies to: SelfReference True

# Then apply the fix
aws ec2 authorize-security-group-ingress --group-id sg-12345678 --protocol -1 --source-group sg-12345678
```

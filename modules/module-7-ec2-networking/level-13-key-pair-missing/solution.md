# Solution

```bash
# Edit the local mission artifact first
$EDITOR network.json
# This edited file applies to: --key-name mission-key

# Then apply the fix
aws ec2 create-key-pair --key-name mission-key
```

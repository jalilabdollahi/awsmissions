# Solution

```bash
# Edit the local mission artifact first
$EDITOR network.json
# This edited file applies to: --group-name mission-sg

# Then apply the fix
aws ec2 create-security-group --group-name mission-sg --description "mission sg" --vpc-id vpc-12345678
```

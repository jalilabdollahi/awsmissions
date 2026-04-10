# Solution

```bash
# Edit the local template or policy artifact first
$EDITOR stack-policy.json
# This edited file applies to: --stack-name mission-stack

# Then apply the fix
aws cloudformation set-stack-policy --stack-name mission-stack --stack-policy-body file://stack-policy.json
```

# Solution

```bash
# Edit the local template or policy artifact first
$EDITOR template.yaml
# This edited file applies to: --stack-name mission-stack

# Then apply the fix
aws cloudformation create-stack --stack-name mission-stack --template-body file://template.yaml
```

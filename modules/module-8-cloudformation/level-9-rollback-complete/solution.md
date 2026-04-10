# Solution

```bash
# Edit the local template or policy artifact first
$EDITOR stack.txt
# This edited file applies to: --stack-name mission-stack

# Then apply the fix
aws cloudformation delete-stack --stack-name mission-stack
```

# Solution

```bash
# Edit the local mission artifact first
$EDITOR alarm-rule.txt
# This edited file applies to: --alarm-name mission-composite

# Then apply the fix
aws cloudwatch put-composite-alarm --alarm-name mission-composite --alarm-rule "ALARM(alarm-a) AND ALARM(alarm-b)"
```

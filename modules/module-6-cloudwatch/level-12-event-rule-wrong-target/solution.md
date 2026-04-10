# Solution

```bash
# Edit the local mission artifact first
$EDITOR target.json
# This edited file applies to: --rule mission-rule

# Then apply the fix
aws events put-targets --rule mission-rule --targets Id=1,Arn=arn:aws:lambda:us-east-1:000000000000:function:mission-function
```

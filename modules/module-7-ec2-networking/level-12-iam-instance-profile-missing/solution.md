# Solution

```bash
# Edit the local mission artifact first
$EDITOR profile.json
# This edited file applies to: --instance-profile-name mission-profile

# Then apply the fix
aws iam create-instance-profile --instance-profile-name mission-profile
```

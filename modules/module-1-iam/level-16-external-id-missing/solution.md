# Solution

```bash
# Edit the local file first
$EDITOR config.json
# This edited file applies to: RoleArn arn:aws:iam::000000000000:role/external-id-role, RoleSessionName mission-session, ExternalId mission-external-id

# Then test the assume-role call
aws sts assume-role --cli-input-json file://config.json
```

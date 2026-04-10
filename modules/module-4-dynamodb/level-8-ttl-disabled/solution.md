# Solution

```bash
aws dynamodb update-time-to-live   --table-name MissionTable   --time-to-live-specification Enabled=true,AttributeName=expiresAt
```

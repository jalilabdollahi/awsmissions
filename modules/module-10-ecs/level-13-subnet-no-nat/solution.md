# Solution

```bash
# Edit the local mission artifact first
$EDITOR network.json
# This edited file applies to: --cluster mission-cluster, --service mission-service

# Then apply the fix
aws ecs update-service --cluster mission-cluster --service mission-service --network-configuration file://network.json
```

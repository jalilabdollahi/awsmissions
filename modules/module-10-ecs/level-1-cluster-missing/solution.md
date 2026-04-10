# Solution

```bash
# Edit the local mission artifact first
$EDITOR ecs.json
# This edited file applies to: cluster mission-cluster

# Then apply the fix
aws ecs create-cluster --cluster-name mission-cluster
```

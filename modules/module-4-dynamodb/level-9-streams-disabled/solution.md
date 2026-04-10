# Solution

```bash
aws dynamodb update-table   --table-name MissionTable   --stream-specification StreamEnabled=true,StreamViewType=NEW_AND_OLD_IMAGES
```

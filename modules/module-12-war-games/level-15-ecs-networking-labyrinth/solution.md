# Solution

```bash
# Update the incident checklist first
$EDITOR incident.md
# This edited file applies to: add nat route

# Then start applying the recovery steps
aws ec2 create-route --route-table-id <rtb> --destination-cidr-block 0.0.0.0/0 --nat-gateway-id <nat-id>
```

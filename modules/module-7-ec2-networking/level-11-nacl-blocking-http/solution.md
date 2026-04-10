# Solution

```bash
# Edit the local mission artifact first
$EDITOR network.json
# This edited file applies to: HttpAllowed True

# Then apply the fix
aws ec2 replace-network-acl-entry --network-acl-id acl-12345678 --rule-number 100 --protocol tcp --port-range From=80,To=80 --cidr-block 0.0.0.0/0 --rule-action allow --egress false
```

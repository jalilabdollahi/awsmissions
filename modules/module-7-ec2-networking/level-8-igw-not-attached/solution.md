# Solution

```bash
# Edit the local mission artifact first
$EDITOR network.json
# This edited file applies to: InternetGatewayAttached True

# Then apply the fix
aws ec2 attach-internet-gateway --internet-gateway-id igw-12345678 --vpc-id vpc-12345678
```

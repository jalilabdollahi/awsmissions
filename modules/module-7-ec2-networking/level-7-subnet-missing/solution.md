# Solution

```bash
# Edit the local mission artifact first
$EDITOR network.json
# This edited file applies to: PublicSubnet subnet-public, PrivateSubnet subnet-private

# Then apply the fix
aws ec2 create-subnet --vpc-id vpc-12345678 --cidr-block 10.0.1.0/24
```

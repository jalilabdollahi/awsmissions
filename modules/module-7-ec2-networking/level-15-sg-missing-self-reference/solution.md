# Solution

Members of the same security group do **not** talk to each other by default. Add rules whose source is the group itself, once for TCP and once for UDP (they are separate protocols).

```bash
SG=$(aws ec2 describe-security-groups --filters Name=group-name,Values=cobalt-nodes-sg --query 'SecurityGroups[0].GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $SG --protocol tcp --port 7946 --source-group $SG
aws ec2 authorize-security-group-ingress --group-id $SG --protocol udp --port 7946 --source-group $SG
```

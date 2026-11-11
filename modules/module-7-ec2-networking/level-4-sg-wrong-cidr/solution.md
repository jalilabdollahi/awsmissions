# Solution

The SSH rule still names the old office range, `198.51.100.0/24`. A rule's source cannot be edited in place with the classic API, so add the new one and remove the old one:

```bash
SG=$(aws ec2 describe-security-groups --filters Name=group-name,Values=nw-bastion-sg --query 'SecurityGroups[0].GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $SG --protocol tcp --port 22 --cidr 203.0.113.0/24
aws ec2 revoke-security-group-ingress    --group-id $SG --protocol tcp --port 22 --cidr 198.51.100.0/24
```

Leave the TCP 9100 monitoring rule alone.

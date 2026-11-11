# Solution

A brand-new security group has no inbound rules, and security groups only contain allow rules, so everything inbound is dropped. Add one rule per port.

```bash
SG=$(aws ec2 describe-security-groups --filters Name=group-name,Values=quillpad-web-sg \
  --query 'SecurityGroups[0].GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $SG --protocol tcp --port 80  --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG --protocol tcp --port 443 --cidr 0.0.0.0/0
```

Check with `aws ec2 describe-security-groups --group-ids $SG`. Do not open a wide port range or all traffic: the validator rejects that.

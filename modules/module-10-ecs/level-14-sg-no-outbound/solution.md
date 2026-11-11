# Solution

Two security groups are involved in every connection and each one has its own rule: the sender's **egress** and the receiver's **ingress**. Here both are missing.

```bash
TASK=$(aws ec2 describe-security-groups --filters Name=group-name,Values=slate-task-sg --query 'SecurityGroups[0].GroupId' --output text)
VPCE=$(aws ec2 describe-security-groups --filters Name=group-name,Values=slate-vpce-sg --query 'SecurityGroups[0].GroupId' --output text)

aws ec2 authorize-security-group-egress  --group-id $TASK --protocol tcp --port 443 --source-group $VPCE
aws ec2 authorize-security-group-ingress --group-id $VPCE --protocol tcp --port 443 --source-group $TASK
aws ec2 revoke-security-group-ingress    --group-id $VPCE --protocol tcp --port 443 --cidr 10.200.99.0/24
```

# Solution

Egress works like ingress: a group with no egress rules lets nothing out. Add exactly the two flows the worker needs.

```bash
WORKER=$(aws ec2 describe-security-groups --filters Name=group-name,Values=parcel-worker-sg --query 'SecurityGroups[0].GroupId' --output text)
DB=$(aws ec2 describe-security-groups --filters Name=group-name,Values=parcel-db-sg --query 'SecurityGroups[0].GroupId' --output text)
aws ec2 authorize-security-group-egress --group-id $WORKER --protocol tcp --port 443  --cidr 0.0.0.0/0
aws ec2 authorize-security-group-egress --group-id $WORKER --protocol tcp --port 5432 --source-group $DB
```

Restoring the allow-all rule would work, but defeats the point of the hardening, so the validator rejects it.

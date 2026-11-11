# Solution

1. Read the real port from Parameter Store:

```bash
aws ssm get-parameter --name /ledger/api/listen-port --query Parameter.Value --output text
```

2. Look up both group ids, then allow that port from the ALB's group and drop the 8080 rule:

```bash
aws ec2 authorize-security-group-ingress --group-id <ledger-api-sg> --protocol tcp --port 3000 --source-group <ledger-alb-sg>
aws ec2 revoke-security-group-ingress    --group-id <ledger-api-sg> --protocol tcp --port 8080 --source-group <ledger-alb-sg>
```

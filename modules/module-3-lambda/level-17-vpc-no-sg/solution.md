# Solution

A security group is the function's identity on the network. The database does not trust IP ranges, it trusts a *group*: `warehouse-db-sg` lets port 5432 in from `etl-clients-sg`. The function carries no group, so it matches no rule.

1. Look at who the database trusts:

```bash
aws ec2 describe-security-groups --filters Name=group-name,Values=warehouse-db-sg \
  --query 'SecurityGroups[0].IpPermissions'
```

The only rule on 5432 names a source group (`UserIdGroupPairs`): `etl-clients-sg`.

2. Attach that group to the function. Include the existing subnets, because `--vpc-config` replaces the block:

```bash
aws lambda get-function-configuration --function-name warehouse-exporter --query VpcConfig.SubnetIds
aws lambda update-function-configuration --function-name warehouse-exporter \
  --vpc-config SubnetIds=<subnet-a>,<subnet-b>,SecurityGroupIds=<etl-clients-sg-id>
```

(Alternatively, create a new group for the function and add a rule to `warehouse-db-sg` that references it. Never open 5432 to a CIDR range, and never attach `bastion-admin-sg`.)

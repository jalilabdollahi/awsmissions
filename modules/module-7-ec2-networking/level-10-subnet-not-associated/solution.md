# Solution

The route table is correct but attached to the wrong subnet. Find the association id that links `fernhill-public` to `fh-data`, drop it, then associate the table with `fh-app`.

```bash
aws ec2 describe-route-tables --filters Name=tag:Name,Values=fernhill-public \
  --query 'RouteTables[0].Associations'
aws ec2 disassociate-route-table --association-id <rtbassoc of fh-data>
aws ec2 associate-route-table --route-table-id <fernhill-public> --subnet-id <fh-app>
```

Once `fh-data` has no explicit association it falls back to the (internet-less) main route table.

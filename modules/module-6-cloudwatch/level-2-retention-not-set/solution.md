# Solution

Retention is a per-log-group setting. The default is *never expire*, which is why groups created automatically by applications grow forever.

1. See the current values (a group without `retentionInDays` never expires):

```bash
aws logs describe-log-groups --log-group-name-prefix /orbit \
  --query 'logGroups[].[logGroupName,retentionInDays]' --output table
```

2. Set 30 days on exactly the three application groups:

```bash
for g in ingest api worker; do
  aws logs put-retention-policy --log-group-name /orbit/$g --retention-in-days 30
done
```

Do not loop over *all* groups: `/orbit/audit` (365 days) and `/billing/invoice-exports` have deliberate values. Run `check` to confirm.

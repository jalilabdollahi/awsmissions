# Solution

1. Find the in-scope tables by tag, not by name:

```bash
for t in $(aws dynamodb list-tables --query 'TableNames[]' --output text); do
  echo "$t: $(aws dynamodb list-tags-of-resource \
    --resource-arn arn:aws:dynamodb:us-east-1:000000000000:table/$t \
    --query 'Tags[?Key==`compliance`].Value' --output text)"
done
```

2. Enable point-in-time recovery on each `compliance=sox` table (`ledger-entries` is already done, `ledger-adjustments` and `payouts-2026` are not):

```bash
aws dynamodb update-continuous-backups --table-name ledger-adjustments \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true
aws dynamodb update-continuous-backups --table-name payouts-2026 \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true
```

`ledger-scratch` stays as it is.

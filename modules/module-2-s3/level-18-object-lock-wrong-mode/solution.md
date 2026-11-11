# Solution

Object Lock is applied per *object version*, and the bucket default only affects objects written afterwards. Two separate changes are needed.

1. See each version's retention:

```bash
aws s3api list-object-versions --bucket fennel-ledger-archive --prefix ledger/
aws s3api get-object-retention --bucket fennel-ledger-archive --key ledger/2025-fy.csv --version-id <id>
aws s3api get-object-lock-configuration --bucket fennel-ledger-archive
```

2. Upgrade every existing version from GOVERNANCE to COMPLIANCE (an upgrade is allowed; the reverse is not), keeping the retain-until date:

```bash
aws s3api put-object-retention --bucket fennel-ledger-archive \
  --key ledger/2025-fy.csv --version-id <id> \
  --retention '{"Mode":"COMPLIANCE","RetainUntilDate":"2028-01-01T00:00:00Z"}'
```

Repeat for all three versions (note that `ledger/2025-fy.csv` has two).

3. Change the default for new objects:

```bash
aws s3api put-object-lock-configuration --bucket fennel-ledger-archive \
  --object-lock-configuration \
  '{"ObjectLockEnabled":"Enabled","Rule":{"DefaultRetention":{"Mode":"COMPLIANCE","Years":7}}}'
```

The validator checks each version's mode, then uploads a fresh object, confirms it picked up COMPLIANCE, and confirms it cannot be removed even with `--bypass-governance-retention`.

# INC-2291  Manifest indexer is failing  (Harbor & Vine Logistics, dispatch platform)

Opened 06:12 by the dispatch desk. Severity: SEV-2.

## Symptom
Since the 05:30 deploy of the freight dashboard, the "Today's manifests" tile is
empty. Drivers can still scan parcels, but no manifest from the overnight
CSV drop has been indexed.

## What we know
- Overnight CSV drop lands in `s3://hv-manifests/incoming/`.
- Lambda `hv-manifest-indexer` reads one manifest (`{"key": "incoming/..."}`),
  copies it to `processed/` in the same bucket, and writes a summary row to the
  DynamoDB table `hv-manifest-index`.
- It runs as IAM role `hv-indexer-role`. The on-call user `hv-oncall` is allowed
  to assume that role for debugging.
- 03:40: someone "froze" the old indexer during an unrelated scare. Nobody wrote
  down what was frozen.
- Another bucket, `hv-payroll-exports`, lives in the same account. Do NOT let
  the indexer near it.

## Runbook
1. Reproduce with `aws lambda invoke` (payload `{"key":"incoming/manifest-20261110.csv"}`).
2. Work out which hop fails: read, copy, or the function configuration itself.
3. Fix only what is broken. Contractors (`hv-contractor`) must stay locked out of
   `restricted/` - that is a legal requirement, not a bug.

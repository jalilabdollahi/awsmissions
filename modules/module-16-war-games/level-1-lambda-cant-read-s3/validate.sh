#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/hv-indexer-role"
probe="$(mktemp)"
trap 'rm -f "$probe"' EXIT
echo "triage $(date +%s)" > "$probe"
remaining=0

echo "INC-2291 triage board"

# Guardrails first: the incident must not become a bigger incident.
if ! aws_local iam get-role --role-name hv-indexer-role >/dev/null 2>&1; then
  echo "hv-indexer-role is gone - the function has nothing to run as."
  exit 1
fi

rc=0
aws_as_role "$ROLE_ARN" hv-oncall "" s3api get-object --bucket hv-payroll-exports --key 2026-10.csv /dev/null >/dev/null 2>&1 || rc=$?
if [ "$rc" -eq 98 ]; then
  echo "hv-oncall can no longer assume the role. Leave the trust policy as it is."
  exit 1
fi
if [ "$rc" -eq 0 ]; then
  echo "BLOCKER: the indexer role can now read hv-payroll-exports. That is a data breach, not a fix."
  exit 1
fi
if aws_as_role "$ROLE_ARN" hv-oncall "" s3api put-object --bucket hv-manifests --key incoming/rogue.csv --body "$probe" >/dev/null 2>&1; then
  echo "BLOCKER: the role can overwrite incoming/ manifests. It only needs read there and write to processed/."
  exit 1
fi
rc=0
aws_as_user hv-contractor s3api get-object --bucket hv-manifests --key restricted/driver-licences.csv /dev/null >/dev/null 2>&1 || rc=$?
if [ "$rc" -eq 0 ]; then
  echo "BLOCKER: hv-contractor can read restricted/ again. The legal wall must stay."
  exit 1
fi

# Hop 1: read the manifest as the role.
if aws_as_role "$ROLE_ARN" hv-oncall "" s3api get-object --bucket hv-manifests --key incoming/manifest-20261110.csv /dev/null >/dev/null 2>&1; then
  echo "[ok]    hop 1  read incoming/ manifest as the role"
else
  echo "[FAULT] hop 1  the role cannot read s3://hv-manifests/incoming/manifest-20261110.csv"
  remaining=$((remaining + 1))
fi

# Hop 2: write the processed copy as the role.
if aws_as_role "$ROLE_ARN" hv-oncall "" s3api put-object --bucket hv-manifests --key processed/triage-probe.csv --body "$probe" >/dev/null 2>&1; then
  echo "[ok]    hop 2  write to processed/ as the role"
else
  echo "[FAULT] hop 2  the role cannot write s3://hv-manifests/processed/"
  remaining=$((remaining + 1))
fi

# Hop 3: the function itself, end to end.
aws_local dynamodb delete-item --table-name hv-manifest-index --key '{"manifest_id":{"S":"incoming/manifest-20261110.csv"}}' >/dev/null 2>&1 || true
out="$(mktemp)"
aws_local lambda invoke --function-name hv-manifest-indexer --cli-binary-format raw-in-base64-out \
  --payload '{"key":"incoming/manifest-20261110.csv"}' "$out" > "$out.meta" 2>&1 || true
fnerr="$(jq -r '.FunctionError // empty' "$out.meta" 2>/dev/null || true)"
rows="$(aws_local dynamodb get-item --table-name hv-manifest-index \
  --key '{"manifest_id":{"S":"incoming/manifest-20261110.csv"}}' --query 'Item.rows.N' --output text 2>/dev/null || true)"
if [ -z "$fnerr" ] && [ "$rows" = "4" ]; then
  echo "[ok]    hop 3  hv-manifest-indexer indexed 4 rows end to end"
else
  echo "[FAULT] hop 3  invoking hv-manifest-indexer does not produce the index row"
  if [ -n "$fnerr" ]; then
    echo "          function said: $(jq -r '.errorType + ": " + .errorMessage' "$out" 2>/dev/null | cut -c1-160)"
  fi
  remaining=$((remaining + 1))
fi
rm -f "$out" "$out.meta"

if [ "$remaining" -gt 0 ]; then
  echo "$remaining hop(s) still broken."
  exit 1
fi
echo "Manifests are flowing again and the guardrails held. Dispatch desk can close INC-2291."

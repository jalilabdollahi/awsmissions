#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

U=orbit-report-svc
T=orbit-shipments

n="$(aws_local dynamodb scan --table-name "$T" --select COUNT --query Count --output text 2>/dev/null || echo 0)"
if [ "$n" != "5" ]; then
  echo "orbit-shipments should still hold its 5 shipments; found $n."
  exit 1
fi

st="$(aws_local dynamodb describe-table --table-name "$T" \
  --query 'Table.GlobalSecondaryIndexes[?IndexName==`by-region-time`].IndexStatus' --output text 2>/dev/null || true)"
if [ -z "$st" ] || [ "$st" = "None" ]; then
  echo "The index by-region-time does not exist on $T."
  exit 1
fi
[ "$st" = "ACTIVE" ] || { echo "by-region-time is $st; wait until ACTIVE."; exit 1; }

# 1. The job's real query, as the job.
set +e
out="$(aws_as_user "$U" dynamodb query --table-name "$T" --index-name by-region-time \
  --key-condition-expression 'region = :r AND shippedAt > :t' \
  --expression-attribute-values '{":r":{"S":"emea"},":t":{"N":"1767050000"}}' \
  --query 'Items[].shipmentId.S' --output text 2>&1)"
rc=$?
set -e
if [ "$rc" -ne 0 ]; then
  if [ "$rc" -eq 97 ]; then echo "The user $U no longer exists."; exit 1; fi
  if printf '%s' "$out" | grep -qi "not authorized"; then
    echo "The index exists, but orbit-report-svc is not allowed to query it:"
  else
    echo "The report query fails:"
  fi
  echo "  $(printf '%s' "$out" | tail -1)"
  exit 1
fi
if [ "$out" != "$(printf 's-1002\ts-1003')" ]; then
  echo "The report for emea after 1767050000 returned [$out]; expected s-1002 and s-1003 in time order."
  exit 1
fi

# 2. Everything else must be refused.
denied() {
  local what="$1" msg="$2"
  shift 2
  if aws_as_user "$U" "$@" >/dev/null 2>&1; then
    echo "$msg"
    exit 1
  fi
}
denied scan "orbit-report-svc can still Scan orbit-shipments. The whole point is to take that away." \
  dynamodb scan --table-name "$T"
denied getitem "orbit-report-svc can fetch single items with GetItem. The job needs Query and nothing else." \
  dynamodb get-item --table-name "$T" --key '{"shipmentId":{"S":"s-1001"}}'
denied write "orbit-report-svc can write to orbit-shipments. A reporting job must be read-only." \
  dynamodb put-item --table-name "$T" --item '{"shipmentId":{"S":"x"},"region":{"S":"emea"},"shippedAt":{"N":"1"}}'
denied payroll "orbit-report-svc can read orbit-payroll. The permission is far too wide: scope the Resource to this table and its index." \
  dynamodb scan --table-name orbit-payroll
echo "The report job queries by-region-time and has no other DynamoDB access."

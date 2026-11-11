#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

T=cartwheel-members

total="$(aws_local dynamodb scan --table-name "$T" --select COUNT --query Count --output text 2>/dev/null || echo 0)"
if [ "$total" -lt 4 ]; then
  echo "cartwheel-members has $total member(s); four riders must still be there. Rebuilding the table would have lost them."
  exit 1
fi

status="$(aws_local dynamodb describe-table --table-name "$T" \
  --query 'Table.GlobalSecondaryIndexes[?IndexName==`email-index`].IndexStatus' --output text 2>/dev/null || true)"
if [ -z "$status" ] || [ "$status" = "None" ]; then
  echo "There is no index called email-index on $T yet."
  exit 1
fi
if [ "$status" != "ACTIVE" ]; then
  echo "email-index exists but is still $status. Give it a moment and run check again."
  exit 1
fi

lookup() {
  aws_local dynamodb query --table-name "$T" --index-name email-index \
    --key-condition-expression 'email = :e' \
    --expression-attribute-values "{\":e\":{\"S\":\"$1\"}}" \
    --query 'Items[0].[memberId.S,plan.S]' --output text 2>&1
}

if ! out="$(lookup ravi@example.org)"; then
  echo "Querying email-index by email failed: $(printf '%s' "$out" | tail -1)"
  exit 1
fi
if [ "$out" != "$(printf 'm-003\tannual')" ]; then
  echo "Looking up ravi@example.org through email-index returned [$out], expected memberId m-003 and plan annual."
  echo "Existing members have to be reachable and the index has to expose memberId and plan."
  exit 1
fi

# A rider who signs up after the fix must appear in the index too.
aws_local dynamodb put-item --table-name "$T" \
  --item '{"memberId":{"S":"m-new"},"email":{"S":"newrider@example.org"},"plan":{"S":"monthly"}}' >/dev/null
out="$(lookup newrider@example.org || true)"
aws_local dynamodb delete-item --table-name "$T" --key '{"memberId":{"S":"m-new"}}' >/dev/null
if [ "$out" != "$(printf 'm-new\tmonthly')" ]; then
  echo "A member created after the index existed was not found through it (got [$out])."
  exit 1
fi

echo "Members can be found by email through email-index, old and new alike."

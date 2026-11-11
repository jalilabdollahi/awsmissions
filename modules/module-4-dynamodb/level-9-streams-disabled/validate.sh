#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

T=greenroom-articles
arn="$(aws_local dynamodb describe-table --table-name "$T" --query 'Table.LatestStreamArn' --output text 2>/dev/null || true)"
enabled="$(aws_local dynamodb describe-table --table-name "$T" --query 'Table.StreamSpecification.StreamEnabled' --output text 2>/dev/null || true)"
if [ "$enabled" != "True" ] && [ "$enabled" != "true" ]; then
  echo "$T has no stream; the audit consumer has nothing to attach to."
  exit 1
fi
count="$(aws_local dynamodb scan --table-name "$T" --select COUNT --query Count --output text)"
if [ "$count" != "2" ]; then
  echo "Expected the two existing articles to still be there, found $count."
  exit 1
fi

# Behaviour: edit an article and read the change record from the stream.
marker="Council passes budget $(date +%s)"
aws_local dynamodb update-item --table-name "$T" --key '{"slug":{"S":"city-budget-vote"}}' \
  --update-expression 'SET headline = :h' --expression-attribute-values "{\":h\":{\"S\":\"$marker\"}}" >/dev/null

shard="$(aws_local dynamodbstreams describe-stream --stream-arn "$arn" \
  --query 'StreamDescription.Shards[0].ShardId' --output text)"
iter="$(aws_local dynamodbstreams get-shard-iterator --stream-arn "$arn" --shard-id "$shard" \
  --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text)"
records="$(aws_local dynamodbstreams get-records --shard-iterator "$iter" --output json)"

verdict="$(printf '%s' "$records" | MARKER="$marker" python3 -c '
import json, os, sys
marker = os.environ["MARKER"]
hit = None
for r in json.load(sys.stdin)["Records"]:
    d = r["dynamodb"]
    new = d.get("NewImage", {}).get("headline", {}).get("S")
    if new == marker:
        hit = d
if hit is None:
    print("missing")
elif "OldImage" not in hit or "NewImage" not in hit:
    print("partial:" + hit.get("StreamViewType", "?"))
elif hit["OldImage"]["headline"]["S"] != "Council votes on budget":
    print("wrongold")
else:
    print("ok")
')"
case "$verdict" in
  ok) echo "Edits to greenroom-articles now emit change records with the before and after image." ;;
  missing)
    echo "The stream is enabled, but the edit I just made did not show up in it."
    exit 1 ;;
  partial:*)
    echo "The change record only carries part of the story (view type ${verdict#partial:}); the audit consumer needs both the old and the new version of the item."
    exit 1 ;;
  *)
    echo "The change record's old image is not the headline before the edit."
    exit 1 ;;
esac

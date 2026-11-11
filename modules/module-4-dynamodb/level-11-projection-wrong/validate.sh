#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

T=shelfwise-books
n="$(aws_local dynamodb scan --table-name "$T" --select COUNT --query Count --output text 2>/dev/null || echo 0)"
if [ "$n" != "3" ]; then
  echo "Expected the 3 books in $T, found $n. Do not rebuild the table."
  exit 1
fi

st="$(aws_local dynamodb describe-table --table-name "$T" \
  --query 'Table.GlobalSecondaryIndexes[?IndexName==`category-index`].IndexStatus' --output text 2>/dev/null || true)"
if [ -z "$st" ] || [ "$st" = "None" ]; then
  echo "category-index does not exist; the category pages query it by name."
  exit 1
fi
if [ "$st" != "ACTIVE" ]; then
  echo "category-index is $st. Wait until it is ACTIVE and check again."
  exit 1
fi

res="$(aws_local dynamodb query --table-name "$T" --index-name category-index \
  --key-condition-expression 'category = :c' --expression-attribute-values '{":c":{"S":"poetry"}}' \
  --output json 2>&1)" || {
  echo "Querying category-index failed: $(printf '%s' "$res" | tail -1)"
  exit 1
}

verdict="$(printf '%s' "$res" | python3 -c '
import json, sys
items = json.load(sys.stdin)["Items"]
if len(items) != 2:
    print("count:%d" % len(items)); sys.exit()
for it in items:
    for a in ("isbn", "price", "title", "author"):
        if a not in it:
            print("missing:" + a); sys.exit()
    if "blurb" in it:
        print("blurb"); sys.exit()
print("ok")
')"
case "$verdict" in
  ok) echo "Category cards have everything they render, and the heavy blurb stays out of the index." ;;
  count:*) echo "Expected 2 poetry books through category-index, got ${verdict#count:}."; exit 1 ;;
  missing:*) echo "Index results still lack the attribute '${verdict#missing:}' that the category cards need."; exit 1 ;;
  blurb) echo "The index now returns the large blurb attribute too. That is the expensive over-fix: project only what the cards render."; exit 1 ;;
esac

#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

T=deskly-tickets
item="$(aws_local dynamodb get-item --table-name "$T" --key '{"ticketId":{"S":"tk-77"}}' --output json 2>/dev/null || echo '{}')"

verdict="$(printf '%s' "$item" | python3 -c '
import json, sys
item = json.load(sys.stdin).get("Item")
if not item:
    print("noitem"); sys.exit()
names = set(item)
for wrong in ("#status", "#s", "#c", "#ts", "#comment", "#timestamp"):
    if wrong in names:
        print("literalname:" + wrong); sys.exit()
if item.get("status", {}).get("S") != "CLOSED":
    print("status:" + str(item.get("status"))); sys.exit()
if not item.get("comment", {}).get("S", "").strip():
    print("nocomment"); sys.exit()
ts = item.get("timestamp", {}).get("N")
if ts is None or int(float(ts)) < 1700000000:
    print("notimestamp"); sys.exit()
if item.get("subject", {}).get("S") != "Refund for double charge" or item.get("agent", {}).get("S") != "mila" \
        or item.get("reopenCount", {}).get("N") != "1":
    print("lostdata"); sys.exit()
print("ok")
')"
case "$verdict" in
  ok) ;;
  noitem) echo "Ticket tk-77 is missing from deskly-tickets."; exit 1 ;;
  literalname:*) echo "The ticket now has an attribute literally called ${verdict#literalname:}. Placeholders must be mapped in ExpressionAttributeNames, not stored as names."; exit 1 ;;
  status:*) echo "tk-77 is not CLOSED yet (status: ${verdict#status:})."; exit 1 ;;
  nocomment) echo "tk-77 has no closing comment."; exit 1 ;;
  notimestamp) echo "tk-77 has no numeric timestamp attribute (epoch seconds)."; exit 1 ;;
  lostdata) echo "Other attributes of tk-77 (subject, agent, reopenCount) were changed or lost. Update the ticket, do not rewrite it."; exit 1 ;;
esac

other="$(aws_local dynamodb get-item --table-name "$T" --key '{"ticketId":{"S":"tk-78"}}' --query 'Item.status.S' --output text)"
if [ "$other" != "OPEN" ]; then
  echo "tk-78 was changed too ($other). Only tk-77 should be closed."
  exit 1
fi

# The script's own request shape must be valid: probe the same expression the player's script should be able to run.
if aws_local dynamodb update-item --table-name "$T" --key '{"ticketId":{"S":"tk-78"}}' \
    --update-expression 'SET status = :x' --expression-attribute-values '{":x":{"S":"X"}}' >/dev/null 2>&1; then
  aws_local dynamodb update-item --table-name "$T" --key '{"ticketId":{"S":"tk-78"}}' \
    --update-expression 'SET #s = :o' --expression-attribute-names '{"#s":"status"}' \
    --expression-attribute-values '{":o":{"S":"OPEN"}}' >/dev/null
  echo "Unexpected: the endpoint accepted a reserved word unescaped. Report this as an emulator issue."
  exit 1
fi
echo "tk-77 is closed with its note and timestamp; nothing else changed."

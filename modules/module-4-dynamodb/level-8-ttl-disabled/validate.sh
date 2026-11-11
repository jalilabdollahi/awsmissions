#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

T=loginly-sessions
read -r status attr <<EOT
$(aws_local dynamodb describe-time-to-live --table-name "$T" \
  --query 'TimeToLiveDescription.[TimeToLiveStatus,AttributeName]' --output text 2>/dev/null || echo "MISSING none")
EOT
if [ "$status" != "ENABLED" ] && [ "$status" != "ENABLING" ]; then
  echo "TTL is not enabled on $T (status: $status)."
  exit 1
fi
if [ "$attr" != "expiresAt" ]; then
  echo "TTL is on, but it watches the attribute '$attr'. Sessions carry their expiry in a different attribute, so no item ever matches."
  exit 1
fi

# Behaviour: a session that is already expired must disappear by itself.
now="$(date +%s)"
aws_local dynamodb put-item --table-name "$T" \
  --item "{\"sessionId\":{\"S\":\"sess-probe\"},\"userId\":{\"S\":\"u-probe\"},\"expiresAt\":{\"N\":\"$((now - 60))\"}}" >/dev/null
gone=0
i=0
while [ "$i" -lt 45 ]; do
  v="$(aws_local dynamodb get-item --table-name "$T" --key '{"sessionId":{"S":"sess-probe"}}' --query 'Item.sessionId.S' --output text)"
  if [ "$v" = "None" ] || [ -z "$v" ]; then gone=1; break; fi
  sleep 2
  i=$((i + 1))
done
if [ "$gone" != "1" ]; then
  aws_local dynamodb delete-item --table-name "$T" --key '{"sessionId":{"S":"sess-probe"}}' >/dev/null || true
  echo "A session that expired a minute ago is still in the table after 90 seconds. TTL is configured but not deleting anything. Is the attribute right, and is its value a number of seconds?"
  exit 1
fi

live="$(aws_local dynamodb get-item --table-name "$T" --key '{"sessionId":{"S":"sess-live"}}' --query 'Item.userId.S' --output text)"
if [ "$live" != "u-12" ]; then
  echo "The still-valid session sess-live was lost. Only expired sessions may disappear."
  exit 1
fi
old="$(aws_local dynamodb get-item --table-name "$T" --key '{"sessionId":{"S":"sess-last-year"}}' --query 'Item.userId.S' --output text)"
if [ "$old" != "None" ]; then
  echo "TTL works for new items, but last year's session is still stored. It should be removed by TTL too."
  exit 1
fi
echo "Expired sessions now delete themselves; live ones stay."

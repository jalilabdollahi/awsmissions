#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb create-table --table-name cartwheel-members \
  --attribute-definitions AttributeName=memberId,AttributeType=S \
  --key-schema AttributeName=memberId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST >/dev/null

for m in "m-001|ines@example.org|annual" "m-002|tobias@example.org|monthly" \
         "m-003|ravi@example.org|annual" "m-004|chen@example.org|day-pass"; do
  id="${m%%|*}"; rest="${m#*|}"; mail="${rest%%|*}"; plan="${rest##*|}"
  aws_local dynamodb put-item --table-name cartwheel-members \
    --item "{\"memberId\":{\"S\":\"$id\"},\"email\":{\"S\":\"$mail\"},\"plan\":{\"S\":\"$plan\"}}"
done

echo "cartwheel-members holds 4 riders. Login-by-email returns HTTP 500."

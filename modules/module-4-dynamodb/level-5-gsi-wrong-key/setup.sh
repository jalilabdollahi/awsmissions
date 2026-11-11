#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb create-table --table-name stockroom-bins \
  --attribute-definitions AttributeName=binId,AttributeType=S AttributeName=aisle,AttributeType=S \
  --key-schema AttributeName=binId,KeyType=HASH \
  --global-secondary-indexes \
  'IndexName=sku-index,KeySchema=[{AttributeName=aisle,KeyType=HASH}],Projection={ProjectionType=ALL}' \
  --billing-mode PAY_PER_REQUEST >/dev/null

for b in "A-01-3|A|BOLT-M8|120" "A-02-1|A|BOLT-M8|8" "B-07-2|B|BOLT-M8|45" "B-07-3|B|WASHER-M8|300" "C-01-1|C|NUT-M8|75"; do
  IFS='|' read -r bin aisle sku qty <<EOT
$b
EOT
  aws_local dynamodb put-item --table-name stockroom-bins \
    --item "{\"binId\":{\"S\":\"$bin\"},\"aisle\":{\"S\":\"$aisle\"},\"sku\":{\"S\":\"$sku\"},\"qty\":{\"N\":\"$qty\"}}"
done
echo "Picklists are failing: sku-index does not answer SKU questions."

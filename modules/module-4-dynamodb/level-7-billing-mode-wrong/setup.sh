#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb create-table --table-name ticketflash-holds \
  --attribute-definitions AttributeName=holdId,AttributeType=S AttributeName=eventId,AttributeType=S \
  --key-schema AttributeName=holdId,KeyType=HASH \
  --billing-mode PROVISIONED --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=10 \
  --global-secondary-indexes \
  'IndexName=event-index,KeySchema=[{AttributeName=eventId,KeyType=HASH}],Projection={ProjectionType=ALL},ProvisionedThroughput={ReadCapacityUnits=5,WriteCapacityUnits=5}' >/dev/null

for h in "h-1|ev-roxy|A12" "h-2|ev-roxy|A13" "h-3|ev-roxy|B02" "h-4|ev-palais|C07" "h-5|ev-palais|C08" "h-6|ev-arena|D44"; do
  id="${h%%|*}"; rest="${h#*|}"; ev="${rest%%|*}"; seat="${rest##*|}"
  aws_local dynamodb put-item --table-name ticketflash-holds \
    --item "{\"holdId\":{\"S\":\"$id\"},\"eventId\":{\"S\":\"$ev\"},\"seat\":{\"S\":\"$seat\"}}"
done

# The abandoned auto scaling experiment.
aws_local application-autoscaling register-scalable-target --service-namespace dynamodb \
  --resource-id table/ticketflash-holds --scalable-dimension dynamodb:table:WriteCapacityUnits \
  --min-capacity 10 --max-capacity 100 >/dev/null

echo "ticketflash-holds is provisioned, with a stale scaling target hanging on it."

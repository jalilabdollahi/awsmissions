#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local application-autoscaling deregister-scalable-target --service-namespace dynamodb \
  --resource-id table/ticketflash-holds --scalable-dimension dynamodb:table:WriteCapacityUnits
aws_local dynamodb update-table --table-name ticketflash-holds --billing-mode PAY_PER_REQUEST >/dev/null

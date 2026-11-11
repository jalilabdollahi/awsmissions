#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

assoc_of() {  # subnet name -> id of the route table explicitly associated, or empty
  local sid
  sid=$(aws_local ec2 describe-subnets --filters Name=tag:Name,Values="$1" --query 'Subnets[0].SubnetId' --output text)
  aws_local ec2 describe-route-tables --filters Name=association.subnet-id,Values="$sid" \
    --query 'RouteTables[0].RouteTableId' --output text
}
PUB=$(aws_local ec2 describe-route-tables --filters Name=tag:Name,Values=fernhill-public --query 'RouteTables[0].RouteTableId' --output text 2>/dev/null || true)
if [ -z "$PUB" ] || [ "$PUB" = "None" ]; then
  echo "The fernhill-public route table was deleted. It was right all along: re-associate it instead."
  exit 1
fi
if ! aws_local ec2 describe-route-tables --route-table-ids "$PUB" \
     --query "RouteTables[0].Routes[?DestinationCidrBlock=='0.0.0.0/0' && starts_with(GatewayId, 'igw-')]" --output text | grep -q igw-; then
  echo "fernhill-public lost its default route to the internet gateway."
  exit 1
fi

DATA_RT=$(assoc_of fh-data)
if [ "$DATA_RT" = "$PUB" ]; then
  echo "fh-data (the private data subnet) is still associated with fernhill-public, so it is exposed to the internet gateway."
  exit 1
fi
if [ "$DATA_RT" != "None" ]; then
  if aws_local ec2 describe-route-tables --route-table-ids "$DATA_RT" \
       --query "RouteTables[0].Routes[?starts_with(GatewayId, 'igw-')]" --output text | grep -q igw-; then
    echo "fh-data uses route table $DATA_RT, which also routes to an internet gateway."
    exit 1
  fi
fi
APP_RT=$(assoc_of fh-app)
if [ "$APP_RT" != "$PUB" ]; then
  echo "fh-app is not associated with fernhill-public yet (it currently falls back to the main route table, which has no internet route)."
  exit 1
fi
echo "fh-app uses fernhill-public and fh-data is isolated again."

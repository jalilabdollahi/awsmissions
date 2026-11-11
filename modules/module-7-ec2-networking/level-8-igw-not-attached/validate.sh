#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 describe-vpcs --filters Name=tag:Name,Values=skyline-prod --query 'Vpcs[0].VpcId' --output text)
SUBNET=$(aws_local ec2 describe-subnets --filters Name=vpc-id,Values="$VPC" --query 'Subnets[0].SubnetId' --output text)
RT_JSON=$(aws_local ec2 describe-route-tables --filters Name=association.subnet-id,Values="$SUBNET" --output json)
GW=$(RT_JSON="$RT_JSON" python3 -c '
import json, os
tables = json.loads(os.environ["RT_JSON"])["RouteTables"]
for t in tables:
    for r in t["Routes"]:
        if r.get("DestinationCidrBlock") == "0.0.0.0/0" and r.get("GatewayId", "").startswith("igw-"):
            print(r["GatewayId"]); raise SystemExit
print("")
')
if [ -z "$GW" ]; then
  echo "The public subnet's route table has no 0.0.0.0/0 route to an internet gateway any more."
  exit 1
fi
ATT=$(aws_local ec2 describe-internet-gateways --internet-gateway-ids "$GW" --query 'InternetGateways[0].Attachments[].VpcId' --output text)
if [ "$ATT" != "$VPC" ]; then
  if [ -z "$ATT" ] || [ "$ATT" = "None" ]; then
    echo "The default route points at $GW, but that internet gateway is not attached to any VPC. A route to a detached gateway carries no traffic."
  else
    echo "The default route points at $GW, which is attached to $ATT, not to skyline-prod ($VPC)."
  fi
  exit 1
fi
NAME=$(aws_local ec2 describe-internet-gateways --internet-gateway-ids "$GW" --query "InternetGateways[0].Tags[?Key=='Name'].Value|[0]" --output text)
if [ "$NAME" != "skyline-igw" ]; then
  echo "Traffic now leaves through $NAME. This VPC must use skyline-igw; legacy-igw belongs to the old project."
  exit 1
fi
RUN=$(aws_local ec2 describe-instances --filters Name=tag:Name,Values=skyline-web Name=instance-state-name,Values=running --query 'length(Reservations)' --output text)
if [ "$RUN" != "1" ]; then
  echo "The skyline-web instance is not running. It did not need touching."
  exit 1
fi
echo "skyline-igw is attached to skyline-prod and the public route leads through it. Orders are flowing."

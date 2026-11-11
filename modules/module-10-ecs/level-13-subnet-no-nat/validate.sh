#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 describe-vpcs --filters Name=tag:Name,Values=lantern --query 'Vpcs[0].VpcId' --output text)
PUB=$(aws_local ec2 describe-subnets --filters Name=vpc-id,Values="$VPC" Name=tag:Name,Values=lantern-public --query 'Subnets[0].SubnetId' --output text)
PRIVRT=$(aws_local ec2 describe-route-tables --filters Name=vpc-id,Values="$VPC" Name=tag:Name,Values=lantern-private-rt --output json)
PUBRT=$(aws_local ec2 describe-route-tables --filters Name=vpc-id,Values="$VPC" Name=tag:Name,Values=lantern-public-rt --output json)
NATS=$(aws_local ec2 describe-nat-gateways --filter Name=vpc-id,Values="$VPC" --output json)

PRIVRT="$PRIVRT" PUBRT="$PUBRT" NATS="$NATS" PUB="$PUB" python3 -c '
import json, os, sys
priv = json.loads(os.environ["PRIVRT"])["RouteTables"][0]
pub = json.loads(os.environ["PUBRT"])["RouteTables"][0]
nats = {n["NatGatewayId"]: n for n in json.loads(os.environ["NATS"])["NatGateways"]}
default = [r for r in priv["Routes"] if r.get("DestinationCidrBlock") == "0.0.0.0/0"]
if not default:
    print("lantern-private-rt has no 0.0.0.0/0 route, so the private subnet still cannot leave the VPC."); sys.exit(1)
r = default[0]
if r.get("GatewayId", "").startswith("igw-"):
    print("The private subnet now routes straight to the internet gateway. That makes it public; send it through a NAT gateway instead."); sys.exit(1)
nat = nats.get(r.get("NatGatewayId", ""))
if nat is None:
    print("The default route of lantern-private-rt targets %s, which is not a NAT gateway in this VPC." % (r.get("NatGatewayId") or r.get("GatewayId") or "nothing")); sys.exit(1)
if nat["State"] not in ("available", "succeeded"):
    print("The NAT gateway %s is %s, not available yet." % (nat["NatGatewayId"], nat["State"])); sys.exit(1)
if nat["SubnetId"] != os.environ["PUB"]:
    print("The NAT gateway sits in %s. It must live in the PUBLIC subnet (lantern-public): the NAT itself needs the internet gateway to reach out." % nat["SubnetId"]); sys.exit(1)
if not any(a.get("AllocationId") for a in nat.get("NatGatewayAddresses", [])):
    print("The NAT gateway has no Elastic IP address."); sys.exit(1)
if not any(x.get("DestinationCidrBlock") == "0.0.0.0/0" and x.get("GatewayId", "").startswith("igw-") for x in pub["Routes"]):
    print("lantern-public-rt lost its internet gateway route; the NAT gateway has no way out."); sys.exit(1)
' || exit 1

alive() {
  local arn
  for arn in $(aws_local ecs list-tasks --cluster lantern --service-name lantern-sync --desired-status RUNNING --query 'taskArns[]' --output text); do
    docker inspect -f '{{.State.Running}}' "floci-aws-${AWSMISSIONS_NAMESPACE}-ecs-${arn##*/}-sync" 2>/dev/null | grep -q true && return 0
  done
  return 1
}
if ! wait_for "lantern-sync to be running" 40 alive; then
  echo "The network path is in place, but lantern-sync has no running task in the private subnet."
  exit 1
fi
echo "lantern-private egresses through a NAT gateway in lantern-public, and lantern-sync is running."

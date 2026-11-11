#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ORD=$(aws_local ec2 describe-vpcs --filters Name=tag:Name,Values=orders-vpc --query 'Vpcs[0].VpcId' --output text)
BIL=$(aws_local ec2 describe-vpcs --filters Name=tag:Name,Values=billing-vpc --query 'Vpcs[0].VpcId' --output text)
PCX=$(aws_local ec2 describe-vpc-peering-connections --filters Name=status-code,Values=active,pending-acceptance \
  --query 'VpcPeeringConnections[0].[VpcPeeringConnectionId,Status.Code]' --output text 2>/dev/null || true)
PCX_ID=$(printf '%s' "$PCX" | awk '{print $1}')
PCX_STATE=$(printf '%s' "$PCX" | awk '{print $2}')
if [ -z "$PCX_ID" ] || [ "$PCX_ID" = "None" ]; then
  echo "There is no live peering connection between the two VPCs."
  exit 1
fi
if [ "$PCX_STATE" != "active" ]; then
  echo "Peering $PCX_ID is $PCX_STATE. The owner of the accepter VPC has to accept the request before any traffic can flow."
  exit 1
fi

rt_json() {  # route table Name tag
  aws_local ec2 describe-route-tables --filters Name=vpc-id,Values="$1" Name=tag:Name,Values="$2" --query 'RouteTables[0].Routes' --output json
}
ROUTES_O=$(rt_json "$ORD" orders-private)
ROUTES_B=$(rt_json "$BIL" billing-private)
SGJ=$(aws_local ec2 describe-security-groups --filters Name=group-name,Values=billing-db-sg --query 'SecurityGroups[0].IpPermissions' --output json)

PCX_ID="$PCX_ID" ROUTES_O="$ROUTES_O" ROUTES_B="$ROUTES_B" SGJ="$SGJ" python3 -c '
import json, os, sys
pcx = os.environ["PCX_ID"]
def check(name, routes, want, other):
    via = [r for r in routes if r.get("VpcPeeringConnectionId") == pcx]
    if any(r.get("DestinationCidrBlock") == "0.0.0.0/0" for r in via):
        print("%s sends 0.0.0.0/0 over the peering. Peering is for the peer CIDR only; this would also hijack internet-bound traffic." % name); sys.exit(1)
    dests = [r.get("DestinationCidrBlock") for r in via]
    if want not in dests:
        print("%s has no route for %s (%s) via %s. Packets need a route in BOTH directions: requests out, replies back." % (name, want, other, pcx)); sys.exit(1)
check("orders-private", json.loads(os.environ["ROUTES_O"]), "10.161.0.0/16", "billing-vpc")
check("billing-private", json.loads(os.environ["ROUTES_B"]), "10.160.0.0/16", "orders-vpc")
perms = json.loads(os.environ["SGJ"])
sources = [r["CidrIp"] for p in perms if p["IpProtocol"] in ("tcp", "-1") for r in p["IpRanges"]
           if p["IpProtocol"] == "-1" or p["FromPort"] <= 5432 <= p["ToPort"]]
if "0.0.0.0/0" in sources:
    print("billing-db-sg opens PostgreSQL to the world. Only the orders VPC (10.160.0.0/16) should connect."); sys.exit(1)
if "10.160.0.0/16" not in sources:
    print("billing-db-sg does not admit the orders VPC range on 5432 (allowed sources: %s)." % (", ".join(sources) or "none")); sys.exit(1)
if "10.162.0.0/16" in sources:
    print("billing-db-sg still allows the stray 10.162.0.0/16 range. Remove the wrong rule."); sys.exit(1)
' || exit 1
echo "orders and billing are peered, routed both ways, and the database admits only the orders VPC."

#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 describe-vpcs --filters Name=tag:Name,Values=harborview-prod --query 'Vpcs[0].VpcId' --output text)
TABLES=$(aws_local ec2 describe-route-tables --filters Name=vpc-id,Values="$VPC" --output json)
SUBNETS=$(aws_local ec2 describe-subnets --filters Name=vpc-id,Values="$VPC" --output json)
IGWS=$(aws_local ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values="$VPC" --query 'InternetGateways[].InternetGatewayId' --output text)

TABLES="$TABLES" SUBNETS="$SUBNETS" IGWS="$IGWS" python3 -c '
import json, os, sys
tables = json.loads(os.environ["TABLES"])["RouteTables"]
subnets = json.loads(os.environ["SUBNETS"])["Subnets"]
igws = os.environ["IGWS"].split()
if not igws:
    print("The internet gateway is no longer attached to the VPC."); sys.exit(1)
main = next(t for t in tables if any(a.get("Main") for a in t["Associations"]))
def tag(s):
    return next((x["Value"] for x in s.get("Tags", []) if x["Key"] == "Name"), s["SubnetId"])
def table_of(subnet_id):
    for t in tables:
        if any(a.get("SubnetId") == subnet_id for a in t["Associations"]):
            return t, True
    return main, False
def goes_to_igw(t):
    return any(r.get("DestinationCidrBlock") == "0.0.0.0/0" and r.get("GatewayId") in igws for r in t["Routes"])
state = {}
for s in subnets:
    t, explicit = table_of(s["SubnetId"])
    state[tag(s)] = (goes_to_igw(t), explicit, t["RouteTableId"])
web, db = state.get("hv-web"), state.get("hv-db")
if db and db[0]:
    why = "the main route table now has an internet route, so every subnet that has no table of its own, including hv-db, inherits it" if not db[1] else "its own route table has an internet route"
    print("hv-db can reach the internet gateway: %s. The database subnet must stay private." % why); sys.exit(1)
if not web[0]:
    print("hv-web still has no 0.0.0.0/0 route to the internet gateway (its effective route table is %s)." % web[2]); sys.exit(1)
if not web[1]:
    print("hv-web only reaches the internet through the main route table. Give the public subnet an explicit route table of its own."); sys.exit(1)
' || exit 1
echo "hv-web is public through its own route table and hv-db is still private."

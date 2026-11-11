#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 describe-vpcs --filters Name=tag:Name,Values=quartz-vpc --query 'Vpcs[0].VpcId' --output text)
EPS=$(aws_local ec2 describe-vpc-endpoints --filters Name=vpc-id,Values="$VPC" Name=service-name,Values=com.amazonaws.us-east-1.s3 --output json)
PRIV=$(aws_local ec2 describe-route-tables --filters Name=vpc-id,Values="$VPC" Name=tag:Name,Values=quartz-private --query 'RouteTables[0]' --output json)
PUB=$(aws_local ec2 describe-route-tables --filters Name=vpc-id,Values="$VPC" Name=tag:Name,Values=quartz-public --query 'RouteTables[0].RouteTableId' --output text)

EPS="$EPS" PRIV="$PRIV" PUB="$PUB" python3 -c '
import json, os, sys
eps = json.loads(os.environ["EPS"])["VpcEndpoints"]
priv = json.loads(os.environ["PRIV"])
pub = os.environ["PUB"]
if not eps:
    print("quartz-vpc has no endpoint for com.amazonaws.us-east-1.s3."); sys.exit(1)
if any(r.get("GatewayId", "").startswith("igw-") or r.get("NatGatewayId") for r in priv["Routes"]):
    print("The private route table now has an internet or NAT route. The point is to reach S3 privately without one."); sys.exit(1)
ep = next((e for e in eps if priv["RouteTableId"] in e.get("RouteTableIds", [])), None)
if ep is None:
    print("An S3 endpoint exists but is not associated with the quartz-private route table, so the batch subnet does not use it."); sys.exit(1)
if ep.get("VpcEndpointType") != "Gateway":
    print("The S3 endpoint must be a Gateway endpoint (it is free and uses route tables)."); sys.exit(1)
if ep.get("State") != "available":
    print("The endpoint is %s, not available yet." % ep.get("State")); sys.exit(1)
if pub in ep.get("RouteTableIds", []):
    print("The endpoint is also attached to the public route table. Only the private subnet needs it."); sys.exit(1)
raw = ep.get("PolicyDocument")
if not raw:
    print("The endpoint has no policy document, so it falls back to full access to every bucket. Compliance requires a restrictive endpoint policy."); sys.exit(1)
doc = json.loads(raw) if isinstance(raw, str) else raw
allowed = set()
for st in doc.get("Statement", []):
    if st.get("Effect") != "Allow":
        continue
    res = st.get("Resource", [])
    res = [res] if isinstance(res, str) else res
    for r in res:
        allowed.add(r)
if not allowed:
    print("The endpoint policy allows nothing; the exports would still fail."); sys.exit(1)
if "*" in allowed or any(not r.startswith("arn:aws:s3:::quartz-exports") for r in allowed):
    print("The endpoint policy allows more than quartz-exports (%s). Scope it to that bucket only." % ", ".join(sorted(allowed))); sys.exit(1)
if not any(r.endswith("/*") for r in allowed):
    print("The policy covers the bucket but not its objects (quartz-exports/*), so uploads would be refused."); sys.exit(1)
' || exit 1
echo "quartz-private reaches S3 through a gateway endpoint that can only touch quartz-exports."

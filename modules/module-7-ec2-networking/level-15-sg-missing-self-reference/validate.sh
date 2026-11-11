#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SG_JSON=$(aws_local ec2 describe-security-groups --filters Name=group-name,Values=cobalt-nodes-sg --query 'SecurityGroups[0]' --output json)
MEMBERS=$(aws_local ec2 describe-instances --filters Name=instance.group-name,Values=cobalt-nodes-sg Name=instance-state-name,Values=pending,running \
  --query 'length(Reservations[].Instances[])' --output text)
if [ "$MEMBERS" != "3" ]; then
  echo "Expected the three cobalt nodes to keep running in cobalt-nodes-sg (found $MEMBERS)."
  exit 1
fi
SG_JSON="$SG_JSON" python3 -c '
import json, os, sys
sg = json.loads(os.environ["SG_JSON"])
me = sg["GroupId"]
perms = sg["IpPermissions"]
def covers(p, proto, port):
    return p["IpProtocol"] == "-1" or (p["IpProtocol"] == proto and p["FromPort"] <= port <= p["ToPort"])
self_ref = lambda p: any(g["GroupId"] == me for g in p["UserIdGroupPairs"])
for p in perms:
    if p["IpRanges"] or p["Ipv6Ranges"]:
        cidrs = [r["CidrIp"] for r in p["IpRanges"]] + [r["CidrIpv6"] for r in p["Ipv6Ranges"]]
        print("A CIDR-based rule exists (%s). Cluster traffic must be admitted by security group reference, not by address range." % ", ".join(cidrs)); sys.exit(1)
    if p["IpProtocol"] == "-1" and self_ref(p):
        print("All traffic is allowed between nodes. Only TCP and UDP 7946 are required; keep the rule narrow."); sys.exit(1)
for proto in ("tcp", "udp"):
    if not any(self_ref(p) and covers(p, proto, 7946) for p in perms):
        print("Nodes still cannot gossip over %s/7946: no rule lets cobalt-nodes-sg members reach each other on that protocol." % proto.upper()); sys.exit(1)
for p in perms:
    if self_ref(p) and (p["ToPort"] - p["FromPort"]) > 0:
        print("The node-to-node rule spans ports %d-%d. Only 7946 is needed." % (p["FromPort"], p["ToPort"])); sys.exit(1)
if not any(p["IpProtocol"] == "tcp" and p["FromPort"] == 9100 and p["UserIdGroupPairs"] for p in perms):
    print("The monitoring rule on 9100 disappeared; it must stay."); sys.exit(1)
' || exit 1
echo "cobalt-nodes-sg members can gossip on TCP and UDP 7946, via self-reference only."

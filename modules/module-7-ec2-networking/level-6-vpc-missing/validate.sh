#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ALL=$(aws_local ec2 describe-vpcs --output json)
VPC=$(ALL="$ALL" python3 -c '
import ipaddress, json, os, sys
vpcs = json.loads(os.environ["ALL"])["Vpcs"]
def name(v):
    return next((t["Value"] for t in v.get("Tags", []) if t["Key"] == "Name"), "")
mine = [v for v in vpcs if name(v) == "meridian-prod"]
if not mine:
    print("There is no VPC named meridian-prod right now."); sys.exit(1)
if len(mine) > 1:
    print("There are %d VPCs named meridian-prod. The review expects exactly one; remove the rejected one." % len(mine)); sys.exit(1)
v = mine[0]
net = ipaddress.ip_network(v["CidrBlock"])
if not net.subnet_of(ipaddress.ip_network("10.0.0.0/8")):
    print("%s is outside 10.0.0.0/8." % net); sys.exit(1)
if not 16 <= net.prefixlen <= 20:
    print("%s is /%d; the review wants a /16 to /20." % (net, net.prefixlen)); sys.exit(1)
for other in vpcs:
    if other["VpcId"] != v["VpcId"] and net.overlaps(ipaddress.ip_network(other["CidrBlock"])):
        print("meridian-prod (%s) still overlaps %s (%s); peering would be impossible." % (net, name(other) or other["VpcId"], other["CidrBlock"])); sys.exit(1)
print(v["VpcId"])
') || { echo "$VPC"; exit 1; }

DNS=$(aws_local ec2 describe-vpc-attribute --vpc-id "$VPC" --attribute enableDnsHostnames --query 'EnableDnsHostnames.Value' --output text)
if [ "$DNS" != "True" ] && [ "$DNS" != "true" ]; then
  echo "meridian-prod ($VPC) has a good CIDR, but DNS hostnames are still disabled."
  exit 1
fi
echo "meridian-prod is a single VPC with non-overlapping space and DNS hostnames on. Review approved."

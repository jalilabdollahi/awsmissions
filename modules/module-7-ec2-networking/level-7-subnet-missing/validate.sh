#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 describe-vpcs --filters Name=tag:Name,Values=brightwave-prod --query 'Vpcs[0].VpcId' --output text 2>/dev/null || true)
if [ -z "$VPC" ] || [ "$VPC" = "None" ]; then
  echo "brightwave-prod no longer exists."
  exit 1
fi
SUBNETS=$(aws_local ec2 describe-subnets --filters Name=vpc-id,Values="$VPC" Name=tag:Tier,Values=public --output json)
IDS=$(SUBNETS="$SUBNETS" python3 -c '
import ipaddress, json, os, sys
subnets = json.loads(os.environ["SUBNETS"])["Subnets"]
if len(subnets) < 2:
    print("Found %d subnet(s) tagged Tier=public in brightwave-prod; need at least two." % len(subnets)); sys.exit(1)
zones = {s["AvailabilityZone"] for s in subnets}
if len(zones) < 2:
    print("All public subnets are in %s. Spread them across different availability zones." % ", ".join(zones)); sys.exit(1)
for s in subnets:
    net = ipaddress.ip_network(s["CidrBlock"])
    if net.prefixlen > 26:
        print("Subnet %s (%s) is smaller than a /26." % (s["SubnetId"], net)); sys.exit(1)
print(" ".join(s["SubnetId"] for s in subnets))
') || { echo "$IDS"; exit 1; }

# Behaviour: ask the load balancer service to use them.
set +e
OUT=$(aws_local elbv2 create-load-balancer --name bw-validate-alb --subnets $IDS \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>&1)
RC=$?
set -e
if [ "$RC" -ne 0 ]; then
  echo "The load balancer service rejected these subnets: $(printf '%s' "$OUT" | tail -1)"
  exit 1
fi
aws_local elbv2 delete-load-balancer --load-balancer-arn "$OUT" >/dev/null 2>&1 || true
echo "brightwave-prod now has a multi-AZ public tier, and an ALB can be created across it."

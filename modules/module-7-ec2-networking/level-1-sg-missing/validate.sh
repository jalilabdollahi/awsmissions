#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 describe-vpcs --filters Name=tag:Name,Values=tindle-prod --query 'Vpcs[0].VpcId' --output text 2>/dev/null || true)
if [ -z "$VPC" ] || [ "$VPC" = "None" ]; then
  echo "The tindle-prod VPC is gone; it must stay in place."
  exit 1
fi

IID=$(aws_local ec2 describe-instances \
  --filters Name=tag:Name,Values=tindle-web-1 Name=instance-state-name,Values=pending,running \
  --query 'Reservations[0].Instances[0].InstanceId' --output text 2>/dev/null || true)
if [ -z "$IID" ] || [ "$IID" = "None" ]; then
  echo "No instance named tindle-web-1 is pending or running yet. Run the launch again once it can succeed."
  exit 1
fi

state_of() { aws_local ec2 describe-instances --instance-ids "$IID" --query 'Reservations[0].Instances[0].State.Name' --output text; }
is_running() { [ "$(state_of)" = running ]; }
if ! wait_for "tindle-web-1 to reach running" 25 is_running; then
  echo "tindle-web-1 ($IID) never reached the running state."
  exit 1
fi

INST_VPC=$(aws_local ec2 describe-instances --instance-ids "$IID" --query 'Reservations[0].Instances[0].VpcId' --output text)
if [ "$INST_VPC" != "$VPC" ]; then
  echo "tindle-web-1 is running, but in $INST_VPC instead of tindle-prod ($VPC)."
  exit 1
fi

SGS=$(aws_local ec2 describe-instances --instance-ids "$IID" --query 'Reservations[0].Instances[0].SecurityGroups[].GroupId' --output text)
https_open=0
for sg in $SGS; do
  rules=$(aws_local ec2 describe-security-groups --group-ids "$sg" --query 'SecurityGroups[0].IpPermissions' --output json)
  verdict=$(printf '%s' "$rules" | python3 -c '
import json, sys
perms = json.load(sys.stdin)
def world(p):
    return any(r.get("CidrIp") == "0.0.0.0/0" for r in p.get("IpRanges", []))
def covers(p, port):
    if p.get("IpProtocol") == "-1":
        return True
    return p.get("IpProtocol") == "tcp" and p.get("FromPort", 0) <= port <= p.get("ToPort", 0)
https = any(world(p) and covers(p, 443) for p in perms)
ssh = any(world(p) and covers(p, 22) for p in perms)
print(("https " if https else "") + ("ssh" if ssh else ""))
')
  case "$verdict" in *ssh*) echo "Security group $sg exposes SSH (port 22) to 0.0.0.0/0. The storefront only needs HTTPS."; exit 1;; esac
  case "$verdict" in *https*) https_open=1;; esac
done
if [ "$https_open" -ne 1 ]; then
  echo "tindle-web-1 is running, but none of its security groups ($SGS) allows inbound TCP 443 from 0.0.0.0/0."
  exit 1
fi
echo "tindle-web-1 is running in tindle-prod behind a group that serves HTTPS and keeps SSH closed. Sale is go."

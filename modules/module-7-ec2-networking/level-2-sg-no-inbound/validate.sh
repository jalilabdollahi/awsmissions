#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

IID=$(aws_local ec2 describe-instances \
  --filters Name=tag:Name,Values=quillpad-web Name=instance-state-name,Values=pending,running \
  --query 'Reservations[0].Instances[0].InstanceId' --output text 2>/dev/null || true)
if [ -z "$IID" ] || [ "$IID" = "None" ]; then
  echo "The quillpad-web instance is not running any more. Fix the group; do not rebuild the instance."
  exit 1
fi

SG=$(aws_local ec2 describe-security-groups --filters Name=group-name,Values=quillpad-web-sg \
  --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || true)
attached=$(aws_local ec2 describe-instances --instance-ids "$IID" \
  --query "Reservations[0].Instances[0].SecurityGroups[?GroupId=='${SG}'].GroupId" --output text)
if [ -z "$SG" ] || [ "$SG" = "None" ] || [ -z "$attached" ]; then
  echo "quillpad-web is no longer protected by quillpad-web-sg. Keep that group attached."
  exit 1
fi

aws_local ec2 describe-security-groups --group-ids "$SG" --query 'SecurityGroups[0].IpPermissions' --output json |
python3 -c '
import json, sys
perms = json.load(sys.stdin)
exposed = set()      # TCP ports reachable from the whole internet
for p in perms:
    if not any(r.get("CidrIp") == "0.0.0.0/0" for r in p.get("IpRanges", [])):
        continue
    if p.get("IpProtocol") == "-1":
        print("quillpad-web-sg allows ALL traffic from 0.0.0.0/0. Open only the two web ports."); sys.exit(1)
    if p.get("IpProtocol") != "tcp":
        print("quillpad-web-sg opens %s traffic to the internet; the blog only speaks TCP." % p.get("IpProtocol")); sys.exit(1)
    lo, hi = p["FromPort"], p["ToPort"]
    if hi - lo > 1 or lo not in (80, 443) or hi not in (80, 443):
        print("quillpad-web-sg opens ports %d-%d to the internet. Only 80 and 443 are needed." % (lo, hi)); sys.exit(1)
    exposed.update(range(lo, hi + 1))
missing = [p for p in (80, 443) if p not in exposed]
if missing:
    names = {80: "HTTP (80)", 443: "HTTPS (443)"}
    print("Readers still cannot reach %s: no inbound rule for it from 0.0.0.0/0." % ", ".join(names[m] for m in missing)); sys.exit(1)
' || exit 1
echo "quillpad-web now accepts HTTP and HTTPS from the internet and nothing else. Readers are back."

#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local ec2 describe-security-groups --filters Name=group-name,Values=nw-bastion-sg \
  --query 'SecurityGroups[0].IpPermissions' --output json |
python3 -c '
import json, sys
perms = json.load(sys.stdin)
ssh_sources, monitoring = [], False
for p in perms:
    cidrs = [r["CidrIp"] for r in p.get("IpRanges", [])]
    if p.get("IpProtocol") == "tcp" and p["FromPort"] == 9100 and "10.60.0.0/16" in cidrs:
        monitoring = True
    if p.get("IpProtocol") == "-1" or (p.get("IpProtocol") == "tcp" and p["FromPort"] <= 22 <= p["ToPort"]):
        ssh_sources.extend(cidrs)
if "0.0.0.0/0" in ssh_sources:
    print("SSH is open to 0.0.0.0/0. A bastion exposed to the world gets brute-forced within minutes."); sys.exit(1)
if "198.51.100.0/24" in ssh_sources:
    print("The old building range 198.51.100.0/24 still has SSH access. It no longer belongs to the company; revoke it."); sys.exit(1)
if "203.0.113.0/24" not in ssh_sources:
    print("SSH from the new office range 203.0.113.0/24 is not allowed yet. SSH sources today: %s" % (", ".join(ssh_sources) or "none")); sys.exit(1)
extra = [c for c in ssh_sources if c != "203.0.113.0/24"]
if extra:
    print("SSH is also allowed from %s. Only the new office range may connect." % ", ".join(extra)); sys.exit(1)
if not monitoring:
    print("The monitoring rule (TCP 9100 from 10.60.0.0/16) was removed. It was unrelated and has to stay."); sys.exit(1)
' || exit 1
echo "SSH to the bastion now comes from 203.0.113.0/24 only. Engineers are connecting again."

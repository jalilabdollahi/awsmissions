#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

PORT=$(aws_local ssm get-parameter --name /ledger/api/listen-port --query Parameter.Value --output text 2>/dev/null || true)
if [ -z "$PORT" ]; then
  echo "The parameter /ledger/api/listen-port has disappeared; it is the source of truth and must stay."
  exit 1
fi
ALB_SG=$(aws_local ec2 describe-security-groups --filters Name=group-name,Values=ledger-alb-sg --query 'SecurityGroups[0].GroupId' --output text)
API_JSON=$(aws_local ec2 describe-security-groups --filters Name=group-name,Values=ledger-api-sg --query 'SecurityGroups[0]' --output json)

printf '%s' "$API_JSON" | python3 -c '
import json, sys
port, alb = int(sys.argv[1]), sys.argv[2]
perms = json.load(sys.stdin)["IpPermissions"]
def spans(p, n):
    return p.get("IpProtocol") == "-1" or (p.get("IpProtocol") == "tcp" and p["FromPort"] <= n <= p["ToPort"])
for p in perms:
    if spans(p, port) and any(r["CidrIp"] == "0.0.0.0/0" for r in p["IpRanges"]):
        print("Port %d is open to 0.0.0.0/0. Only the load balancer group may reach the API." % port); sys.exit(1)
via_alb = any(spans(p, port) and any(g["GroupId"] == alb for g in p["UserIdGroupPairs"]) for p in perms)
if not via_alb:
    print("ledger-api-sg does not yet allow TCP %d from the ledger-alb-sg group, so the ALB health checks keep failing." % port); sys.exit(1)
if port != 8080 and any(spans(p, 8080) for p in perms):
    print("The old 8080 opening is still there. Nothing listens on 8080; remove the stale rule."); sys.exit(1)
if any(p.get("IpRanges") for p in perms):
    print("ledger-api-sg has a CIDR-based rule. Traffic should be admitted by source security group only."); sys.exit(1)
' "$PORT" "$ALB_SG" || exit 1
echo "ledger-api-sg admits the ALB on port $PORT and nothing else."

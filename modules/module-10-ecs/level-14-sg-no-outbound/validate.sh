#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TASK=$(aws_local ec2 describe-security-groups --filters Name=group-name,Values=slate-task-sg --query 'SecurityGroups[0]' --output json)
VPCE=$(aws_local ec2 describe-security-groups --filters Name=group-name,Values=slate-vpce-sg --query 'SecurityGroups[0]' --output json)
EPS=$(aws_local ec2 describe-vpc-endpoints --query "VpcEndpoints[?contains(ServiceName,'ecr') || contains(ServiceName,'logs') || contains(ServiceName,'secretsmanager')].Groups[].GroupId" --output text)

TASK="$TASK" VPCE="$VPCE" EPS="$EPS" python3 -c '
import json, os, sys
task, vpce = json.loads(os.environ["TASK"]), json.loads(os.environ["VPCE"])
t_id, v_id = task["GroupId"], vpce["GroupId"]
if v_id not in os.environ["EPS"].split():
    print("slate-vpce-sg is no longer attached to the interface endpoints."); sys.exit(1)
def tcp443(p):
    return p["IpProtocol"] == "-1" or (p["IpProtocol"] == "tcp" and p["FromPort"] <= 443 <= p["ToPort"])
for side, perms in (("slate-task-sg egress", task["IpPermissionsEgress"]), ("slate-vpce-sg ingress", vpce["IpPermissions"])):
    for p in perms:
        if any(r["CidrIp"] == "0.0.0.0/0" for r in p["IpRanges"]):
            print("%s contains a rule for 0.0.0.0/0. The endpoints are internal; nothing should be opened to the world." % side); sys.exit(1)
        if p["IpProtocol"] == "-1":
            print("%s allows all protocols and ports. Only HTTPS between the two groups is needed." % side); sys.exit(1)
egress_ok = any(tcp443(p) and any(g["GroupId"] == v_id for g in p["UserIdGroupPairs"]) for p in task["IpPermissionsEgress"])
if not egress_ok:
    print("slate-task-sg cannot send HTTPS to the endpoints: it has no egress rule for TCP 443 towards slate-vpce-sg."); sys.exit(1)
ingress_ok = any(tcp443(p) and any(g["GroupId"] == t_id for g in p["UserIdGroupPairs"]) for p in vpce["IpPermissions"])
if not ingress_ok:
    print("slate-task-sg can send HTTPS, but slate-vpce-sg does not accept it from the task group. Each side of the conversation needs its own rule."); sys.exit(1)
stale = [r["CidrIp"] for p in vpce["IpPermissions"] for r in p["IpRanges"]]
if stale:
    print("slate-vpce-sg still trusts address ranges (%s) instead of the task group. Remove the stale CIDR rule." % ", ".join(stale)); sys.exit(1)
' || exit 1
echo "slate-task-sg -> slate-vpce-sg on 443 is open in both directions, and nothing else is."

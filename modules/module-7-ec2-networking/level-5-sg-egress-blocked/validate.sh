#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

DB=$(aws_local ec2 describe-security-groups --filters Name=group-name,Values=parcel-db-sg --query 'SecurityGroups[0].GroupId' --output text)
WORKER_JSON=$(aws_local ec2 describe-security-groups --filters Name=group-name,Values=parcel-worker-sg --query 'SecurityGroups[0]' --output json)
DB_JSON=$(aws_local ec2 describe-security-groups --group-ids "$DB" --query 'SecurityGroups[0]' --output json)

WORKER_JSON="$WORKER_JSON" DB_JSON="$DB_JSON" python3 -c '
import json, os, sys
worker, db = json.loads(os.environ["WORKER_JSON"]), json.loads(os.environ["DB_JSON"])
db_id = db["GroupId"]
egress = worker["IpPermissionsEgress"]
https = pg = False
for rule in egress:
    cidrs = [r["CidrIp"] for r in rule.get("IpRanges", [])]
    groups = [g["GroupId"] for g in rule.get("UserIdGroupPairs", [])]
    proto = rule.get("IpProtocol")
    if proto == "-1":
        print("The group allows all outbound traffic again. Security asked for a locked-down group: allow only HTTPS and PostgreSQL."); sys.exit(1)
    lo, hi = rule["FromPort"], rule["ToPort"]
    if proto == "tcp" and lo <= 443 <= hi and "0.0.0.0/0" in cidrs:
        if hi - lo > 0:
            print("Egress ports %d-%d to the internet are wider than HTTPS alone." % (lo, hi)); sys.exit(1)
        https = True
    if proto == "tcp" and lo <= 5432 <= hi:
        if "0.0.0.0/0" in cidrs:
            print("PostgreSQL egress to the whole internet is too broad. The database is reached through its security group."); sys.exit(1)
        if db_id in groups or "10.50.0.0/16" in cidrs:
            pg = True
if not https:
    print("The worker still cannot call the tracking API: no outbound TCP 443 rule to 0.0.0.0/0."); sys.exit(1)
if not pg:
    print("The worker still cannot reach PostgreSQL: no outbound TCP 5432 rule towards parcel-db-sg."); sys.exit(1)
ingress_ok = any(p.get("FromPort") == 5432 and any(g["GroupId"] == worker["GroupId"] for g in p["UserIdGroupPairs"]) for p in db["IpPermissions"])
if not ingress_ok:
    print("parcel-db-sg no longer admits the worker group on 5432. Leave the database group as it was."); sys.exit(1)
' || exit 1
echo "parcel-worker-sg can reach HTTPS and PostgreSQL only. Tracking and database calls work again."

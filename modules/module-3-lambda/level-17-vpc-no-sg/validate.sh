#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

res="$(mktemp)"; hdr="$(mktemp)"
trap 'rm -f "$res" "$hdr"' EXIT

cfg="$(aws_local lambda get-function-configuration --function-name warehouse-exporter --output json)"
groups="$(printf '%s' "$cfg" | jq -r '.VpcConfig.SecurityGroupIds[]?')"
n_subnets="$(printf '%s' "$cfg" | jq '.VpcConfig.SubnetIds | length')"

if [ "$n_subnets" -lt 2 ]; then
  echo "The function's subnets were removed; it must stay in its two analytics-vpc subnets."
  exit 1
fi
if [ -z "$groups" ]; then
  echo "The function still has no security group, so it has no firewall identity the database could trust."
  exit 1
fi

vpc="$(aws_local ec2 describe-vpcs --filters Name=tag:Name,Values=analytics-vpc --query 'Vpcs[0].VpcId' --output text)"
db="$(aws_local ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc" Name=group-name,Values=warehouse-db-sg \
  --query 'SecurityGroups[0].GroupId' --output text)"
bastion="$(aws_local ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc" Name=group-name,Values=bastion-admin-sg \
  --query 'SecurityGroups[0].GroupId' --output text)"

# The database firewall must not have been opened up.
dbinfo="$(aws_local ec2 describe-security-groups --group-ids "$db" --output json)"
if printf '%s' "$dbinfo" | jq -e '[.SecurityGroups[0].IpPermissions[] | select(.IpRanges | length > 0)] | length > 0' >/dev/null; then
  echo "warehouse-db-sg now accepts traffic from an IP range. The database may only trust specific security groups."
  exit 1
fi

trusted=""
for g in $groups; do
  gv="$(aws_local ec2 describe-security-groups --group-ids "$g" --query 'SecurityGroups[0].VpcId' --output text 2>/dev/null || true)"
  if [ "$gv" != "$vpc" ]; then
    echo "Security group $g is not in analytics-vpc."
    exit 1
  fi
  if [ "$g" = "$bastion" ]; then
    echo "bastion-admin-sg is attached to the function. That group is for jump hosts only."
    exit 1
  fi
  if printf '%s' "$dbinfo" | jq -e --arg g "$g" \
       '[.SecurityGroups[0].IpPermissions[] | select(.IpProtocol=="tcp" and .FromPort<=5432 and .ToPort>=5432) | .UserIdGroupPairs[].GroupId] | index($g) != null' >/dev/null; then
    trusted="$g"
  fi
done
if [ -z "$trusted" ]; then
  echo "None of the function's security groups ($(printf '%s' "$groups" | tr '\n' ' ')) is allowed by warehouse-db-sg on port 5432. The database only admits the groups it lists as sources."
  exit 1
fi

aws_local lambda invoke --function-name warehouse-exporter --cli-binary-format raw-in-base64-out \
  --payload '{"tables":[{"rows":120},{"rows":80}]}' "$res" >"$hdr" 2>&1 || { echo "Invoke failed: $(tail -1 "$hdr")"; exit 1; }
if [ "$(jq -r '.rows // empty' "$res")" != "200" ]; then
  echo "The exporter no longer works: $(head -c 200 "$res")"
  exit 1
fi

echo "warehouse-exporter carries $trusted, which warehouse-db-sg admits on 5432, and the database firewall is still tight."

#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

res="$(mktemp)"; hdr="$(mktemp)"
trap 'rm -f "$res" "$hdr"' EXIT

cfg="$(aws_local lambda get-function-configuration --function-name order-sync --output json)"
subnets="$(printf '%s' "$cfg" | jq -r '.VpcConfig.SubnetIds[]?')"
groups="$(printf '%s' "$cfg" | jq -r '.VpcConfig.SecurityGroupIds[]?')"

if [ -z "$subnets" ]; then
  echo "order-sync has no subnets in its network configuration, so Lambda cannot place it in any VPC."
  exit 1
fi

orders_vpc="$(aws_local ec2 describe-vpcs --filters Name=tag:Name,Values=orders-vpc --query 'Vpcs[0].VpcId' --output text)"
count=0
azs=""
for s in $subnets; do
  info="$(aws_local ec2 describe-subnets --subnet-ids "$s" --query 'Subnets[0].[VpcId,AvailabilityZone]' --output text 2>/dev/null || true)"
  if [ -z "$info" ]; then
    echo "Subnet $s does not exist."
    exit 1
  fi
  vpc="$(printf '%s' "$info" | awk '{print $1}')"
  az="$(printf '%s' "$info" | awk '{print $2}')"
  if [ "$vpc" != "$orders_vpc" ]; then
    echo "Subnet $s belongs to $vpc, not to orders-vpc ($orders_vpc). The database is not reachable from there."
    exit 1
  fi
  igw_routes="$(aws_local ec2 describe-route-tables --filters "Name=association.subnet-id,Values=$s" --output json \
    | jq '[.RouteTables[].Routes[] | select((.GatewayId // "") | startswith("igw-"))] | length')"
  if [ "$igw_routes" != "0" ]; then
    echo "Subnet $s is public (its route table sends 0.0.0.0/0 to an internet gateway). Lambda functions belong in private subnets."
    exit 1
  fi
  count=$((count + 1))
  case " $azs " in *" $az "*) ;; *) azs="$azs $az" ;; esac
done
az_count="$(printf '%s\n' $azs | wc -l | tr -d ' ')"
if [ "$az_count" -lt 2 ]; then
  echo "All subnets ($count) are in a single availability zone ($azs ). Losing that zone would take the function down; use at least two."
  exit 1
fi

for g in $groups; do
  gv="$(aws_local ec2 describe-security-groups --group-ids "$g" --query 'SecurityGroups[0].VpcId' --output text)"
  if [ "$gv" != "$orders_vpc" ]; then
    echo "Security group $g is not in orders-vpc."
    exit 1
  fi
done
if [ -z "$groups" ]; then
  echo "The function lost its security group. It needs order-sync-sg, which the database firewall trusts."
  exit 1
fi

aws_local lambda invoke --function-name order-sync --cli-binary-format raw-in-base64-out \
  --payload '{"orders":[{"id":1},{"id":2},{"id":3}]}' "$res" >"$hdr" 2>&1 || { echo "Invoke failed: $(tail -1 "$hdr")"; exit 1; }
if [ "$(jq -r '.synced // empty' "$res")" != "3" ]; then
  echo "order-sync does not run properly any more: $(head -c 200 "$res")"
  exit 1
fi

echo "order-sync runs in orders-vpc on $count private subnets across $az_count availability zones."

#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

NS=$(aws_local servicediscovery list-namespaces --query "Namespaces[?Name=='shop.local'].[Id,Type]" --output text 2>/dev/null || true)
NS_ID=$(printf '%s' "$NS" | awk '{print $1}')
NS_TYPE=$(printf '%s' "$NS" | awk '{print $2}')
if [ -z "$NS_ID" ]; then
  echo "There is no Cloud Map namespace named shop.local yet."
  exit 1
fi
if [ "$NS_TYPE" != "DNS_PRIVATE" ]; then
  echo "shop.local exists but is of type $NS_TYPE. Names inside the VPC need a private DNS namespace."
  exit 1
fi
SD=$(aws_local servicediscovery list-services --filters "Name=NAMESPACE_ID,Values=$NS_ID,Condition=EQ" \
  --query "Services[?Name=='inventory'].[Id,Arn]" --output text 2>/dev/null || true)
SD_ID=$(printf '%s' "$SD" | awk '{print $1}')
SD_ARN=$(printf '%s' "$SD" | awk '{print $2}')
if [ -z "$SD_ID" ]; then
  echo "The namespace exists, but it has no service named inventory."
  exit 1
fi
RECS=$(aws_local servicediscovery get-service --id "$SD_ID" --query 'Service.DnsConfig.DnsRecords[].Type' --output text)
case "$RECS" in
  *A*) ;;
  *) echo "The Cloud Map service has no A record configuration (it has: ${RECS:-none}). awsvpc tasks are discovered by their IPv4 address."; exit 1;;
esac
REG=$(aws_local ecs describe-services --cluster shop --services inventory --query 'services[0].serviceRegistries[].registryArn' --output text)
if [ "$REG" != "$SD_ARN" ]; then
  echo "The ECS inventory service is not registered with the Cloud Map service (its registries: ${REG:-none})."
  exit 1
fi

task_ips() {
  local arn
  for arn in $(aws_local ecs list-tasks --cluster shop --service-name inventory --desired-status RUNNING --query 'taskArns[]' --output text); do
    docker inspect -f '{{.State.Running}}' "floci-aws-ecs-${arn##*/}-inventory" 2>/dev/null | grep -q true || continue
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "floci-aws-ecs-${arn##*/}-inventory"
  done | sort
}
registered_ips() {
  aws_local servicediscovery list-instances --service-id "$SD_ID" --query 'Instances[].Attributes.AWS_INSTANCE_IPV4' --output text | tr '\t' '\n' | sort
}
matches() {
  local t r
  t=$(task_ips); r=$(registered_ips)
  [ -n "$t" ] && [ "$(printf '%s\n' "$t" | wc -l | tr -d ' ')" -ge 2 ] && [ "$t" = "$r" ]
}
if ! wait_for "Cloud Map to list exactly the running inventory tasks" 60 matches; then
  echo "Cloud Map lists [$(registered_ips | tr '\n' ' ')] but the two running inventory tasks are at [$(task_ips | tr '\n' ' ')]."
  exit 1
fi
echo "inventory.shop.local is backed by exactly the live inventory tasks."

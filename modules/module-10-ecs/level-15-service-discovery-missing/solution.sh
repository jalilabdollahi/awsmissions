#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local servicediscovery create-private-dns-namespace --name shop.local --vpc vpc-default-us-east-1 >/dev/null
have_ns() { [ -n "$(aws_local servicediscovery list-namespaces --query "Namespaces[?Name=='shop.local'].Id" --output text)" ]; }
wait_for "namespace shop.local" 30 have_ns
NS=$(aws_local servicediscovery list-namespaces --query "Namespaces[?Name=='shop.local'].Id" --output text)
ARN=$(aws_local servicediscovery create-service --name inventory --namespace-id "$NS" \
  --dns-config 'RoutingPolicy=MULTIVALUE,DnsRecords=[{Type=A,TTL=10}]' --query Service.Arn --output text)
aws_local ecs update-service --cluster shop --service inventory --service-registries "registryArn=$ARN" >/dev/null

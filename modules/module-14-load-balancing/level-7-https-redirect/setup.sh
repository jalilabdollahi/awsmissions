#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

LB=$(aws_local elbv2 create-load-balancer --name quillstone-alb \
  --subnets subnet-default-us-east-1-b subnet-default-us-east-1-c \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)

# The legacy redirect: temporary, odd port, and a hard-coded path.
aws_local elbv2 create-listener --load-balancer-arn "$LB" --protocol HTTP --port 80 \
  --default-actions '[{"Type":"redirect","RedirectConfig":{"Protocol":"HTTPS","Port":"8443","Path":"/","StatusCode":"HTTP_302"}}]' >/dev/null

echo "quillstone-alb redirects HTTP to HTTPS, but the redirect is temporary, on port 8443, and drops the path."

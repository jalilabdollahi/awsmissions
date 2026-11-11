#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local ec2 create-vpc --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=shared-services}]' >/dev/null
# The rushed attempt: overlaps shared-services, no DNS hostnames.
aws_local ec2 create-vpc --cidr-block 10.0.0.0/20 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=meridian-prod}]' >/dev/null
echo "A meridian-prod VPC exists, but it overlaps shared-services (10.0.0.0/16)."

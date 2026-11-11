#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local ec2 create-vpc --cidr-block 10.70.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=brightwave-prod}]' >/dev/null
echo "brightwave-prod exists, with zero subnets."

#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Supply the value at deploy time; the template stays reusable for other shops.
aws_local cloudformation create-stack --stack-name fernwood-orders \
  --template-body file://template.yaml \
  --parameters ParameterKey=BranchCode,ParameterValue=dub >/dev/null
aws_local cloudformation wait stack-create-complete --stack-name fernwood-orders

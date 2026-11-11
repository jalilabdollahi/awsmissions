#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 describe-vpcs --filters Name=tag:Name,Values=tindle-prod --query 'Vpcs[0].VpcId' --output text)
SG=$(aws_local ec2 create-security-group --group-name tindle-storefront --description "Tindle storefront HTTPS" \
  --vpc-id "$VPC" --query GroupId --output text)
aws_local ec2 authorize-security-group-ingress --group-id "$SG" --protocol tcp --port 443 --cidr 0.0.0.0/0 >/dev/null

python3 - "$SG" <<'PY'
import sys
text = open("launch-web.sh").read().replace("sg-0a11c0de5afe0001", sys.argv[1])
open("launch-web.sh", "w").write(text)
PY
bash launch-web.sh >/dev/null

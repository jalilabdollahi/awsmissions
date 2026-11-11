#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Line 9 starts one column too far right; pull it back under "Resources:".
sed 's/^   DelayTopic:/  DelayTopic:/' template.yaml > template.fixed
mv template.fixed template.yaml

aws_local cloudformation create-stack --stack-name harborlights-core \
  --template-body file://template.yaml >/dev/null
aws_local cloudformation wait stack-create-complete --stack-name harborlights-core

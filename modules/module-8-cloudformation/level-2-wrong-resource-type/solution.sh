#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

sed 's/AWS::S3::Bukcet/AWS::S3::Bucket/' template.yaml > template.corrected
mv template.corrected template.yaml

# Preview the change as a change set, then run it.
aws_local cloudformation create-change-set --stack-name brightwater-intake \
  --change-set-name fix-bucket-type --template-body file://template.yaml >/dev/null
aws_local cloudformation wait change-set-create-complete \
  --stack-name brightwater-intake --change-set-name fix-bucket-type
aws_local cloudformation execute-change-set --stack-name brightwater-intake \
  --change-set-name fix-bucket-type
aws_local cloudformation wait stack-update-complete --stack-name brightwater-intake

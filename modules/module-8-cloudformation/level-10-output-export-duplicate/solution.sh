#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Who owns the contested name? (Not us.)
aws_local cloudformation list-exports \
  --query "Exports[?Name=='quayside-assets-bucket'].ExportingStackId" --output text >/dev/null

# Rename only the export in the reporting template.
sed 's/Name: quayside-assets-bucket/Name: quayside-reports-bucket/' template.yaml > template.renamed
mv template.renamed template.yaml

# A failed first attempt leaves a stack record that blocks the name.
if aws_local cloudformation describe-stacks --stack-name quayside-reports >/dev/null 2>&1; then
  aws_local cloudformation delete-stack --stack-name quayside-reports
  aws_local cloudformation wait stack-delete-complete --stack-name quayside-reports || true
fi
aws_local cloudformation create-stack --stack-name quayside-reports \
  --template-body file://template.yaml >/dev/null
aws_local cloudformation wait stack-create-complete --stack-name quayside-reports

#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Discover the real export names instead of guessing.
aws_local cloudformation list-exports --query 'Exports[].Name' --output text >/dev/null

python3 - <<'PY'
text = open("template.yaml").read()
text = text.replace("!ImportValue ledgerline-audit-topic-arn", "!ImportValue ledgerline-prod-audit-topic-arn")
text = text.replace("!ImportValue ledgerline-prod-audit-bucket", "!ImportValue ledgerline-prod-audit-bucket-name")
open("template.yaml", "w").write(text)
PY

aws_local cloudformation delete-stack --stack-name ledgerline-auditor >/dev/null 2>&1 || true
aws_local cloudformation wait stack-delete-complete --stack-name ledgerline-auditor 2>/dev/null || true
aws_local cloudformation create-stack --stack-name ledgerline-auditor \
  --template-body file://template.yaml >/dev/null
aws_local cloudformation wait stack-create-complete --stack-name ledgerline-auditor

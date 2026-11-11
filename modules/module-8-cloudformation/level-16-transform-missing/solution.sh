#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Insert the SAM transform declaration directly under the format version line.
python3 - <<'PY'
out = []
for line in open("template.yaml").read().split("\n"):
    out.append(line)
    if line.startswith("AWSTemplateFormatVersion"):
        out.append("Transform: AWS::Serverless-2016-10-31")
open("template.yaml", "w").write("\n".join(out))
PY

# Expansion only happens at creation, so any earlier green-but-empty stack must go first.
if aws_local cloudformation describe-stacks --stack-name parcelhub-notifier >/dev/null 2>&1; then
  aws_local cloudformation delete-stack --stack-name parcelhub-notifier
  aws_local cloudformation wait stack-delete-complete --stack-name parcelhub-notifier || true
fi
aws_local cloudformation create-stack --stack-name parcelhub-notifier \
  --template-body file://template.yaml --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND >/dev/null
aws_local cloudformation wait stack-create-complete --stack-name parcelhub-notifier

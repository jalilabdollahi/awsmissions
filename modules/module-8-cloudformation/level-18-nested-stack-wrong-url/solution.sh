#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Find the real key of the child template, then fix all three mistakes.
aws_local s3 ls s3://crescent-templates --recursive >/dev/null

python3 - <<'PY'
text = open("template.yaml").read()
text = text.replace("crescent-templates/templates/alerts.yaml",
                    "crescent-templates/shared/alerting/topic-stack.yaml")
text = text.replace("Team: billing", "TeamName: billing")
text = text.replace("Alerts.Outputs.Arn", "Alerts.Outputs.AlertTopicArn")
open("template.yaml", "w").write(text)
PY

aws_local cloudformation delete-stack --stack-name crescent-platform
aws_local cloudformation wait stack-delete-complete --stack-name crescent-platform
aws_local cloudformation create-stack --stack-name crescent-platform \
  --template-body file://template.yaml >/dev/null
aws_local cloudformation wait stack-create-complete --stack-name crescent-platform

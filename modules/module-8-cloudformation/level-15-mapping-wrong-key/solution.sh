#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Walk the file and repair the one mis-spelled map key.
python3 - <<'PY'
lines = open("template.yaml").read().split("\n")
for i, line in enumerate(lines):
    if line.strip() == "us-east1:":
        lines[i] = line.replace("us-east1", "us-east-1")
open("template.yaml", "w").write("\n".join(lines))
PY

# The rolled-back stack record has to go before the name can be reused.
aws_local cloudformation delete-stack --stack-name cobalt-reminders
aws_local cloudformation wait stack-delete-complete --stack-name cobalt-reminders || true
aws_local cloudformation create-stack --stack-name cobalt-reminders \
  --template-body file://template.yaml >/dev/null
aws_local cloudformation wait stack-create-complete --stack-name cobalt-reminders

#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Mark the stateful resources as Retain BEFORE deleting; the policy is read from
# the template that is currently deployed.
python3 - <<'PY'
text = open("template.yaml").read()
for logical in ("LedgerArchive", "LedgerIndex"):
    text = text.replace("  %s:\n    Type:" % logical, "  %s:\n    DeletionPolicy: Retain\n    Type:" % logical)
open("template.yaml", "w").write(text)
PY

aws_local cloudformation update-stack --stack-name nightjar-archive \
  --template-body file://template.yaml >/dev/null
aws_local cloudformation wait stack-update-complete --stack-name nightjar-archive

aws_local cloudformation delete-stack --stack-name nightjar-archive
aws_local cloudformation wait stack-delete-complete --stack-name nightjar-archive

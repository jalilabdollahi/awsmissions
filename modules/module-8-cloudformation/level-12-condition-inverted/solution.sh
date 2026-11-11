#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# IsProduction compared the environment with "dev"; production means "prod".
python3 - <<'PY'
text = open("template.yaml").read()
open("template.yaml", "w").write(text.replace("!Equals [!Ref Environment, dev]", "!Equals [!Ref Environment, prod]"))
PY

aws_local cloudformation update-stack --stack-name marlow-catalog \
  --template-body file://template.yaml \
  --parameters ParameterKey=Environment,UsePreviousValue=true >/dev/null
aws_local cloudformation wait stack-update-complete --stack-name marlow-catalog

#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
text = open("billing.py").read()
open("billing.py", "w").write(text.replace('"AT_SEQUENCE_NUMBER"', '"AFTER_SEQUENCE_NUMBER"'))
PY

rm -f billing.zip
zip -q billing.zip billing.py
aws_local lambda update-function-code --function-name billing-resume --zip-file fileb://billing.zip >/dev/null
wait_for "function update" 30 aws_local lambda wait function-updated --function-name billing-resume

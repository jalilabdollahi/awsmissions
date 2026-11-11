#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
text = open("audit.py").read()
open("audit.py", "w").write(text.replace('ShardIteratorType="LATEST"', 'ShardIteratorType="TRIM_HORIZON"'))
PY

rm -f audit.zip
zip -q audit.zip audit.py
aws_local lambda update-function-code --function-name swipe-audit --zip-file fileb://audit.zip >/dev/null
wait_for "function update" 30 aws_local lambda wait function-updated --function-name swipe-audit

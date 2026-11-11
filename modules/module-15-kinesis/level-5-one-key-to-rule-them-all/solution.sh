#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
text = open("publisher.py").read()
open("publisher.py", "w").write(text.replace('"PartitionKey": "order-service"', '"PartitionKey": item["order_id"]'))
PY

rm -f publisher.zip
zip -q publisher.zip publisher.py
aws_local lambda update-function-code --function-name order-publisher --zip-file fileb://publisher.zip >/dev/null
wait_for "function update" 30 aws_local lambda wait function-updated --function-name order-publisher

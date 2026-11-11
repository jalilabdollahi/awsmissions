#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# 1. dump the data
aws_local dynamodb scan --table-name clinic-appointments --output json > appointments-dump.json

# 2. replace the table with one that has the LSI from the start
aws_local dynamodb delete-table --table-name clinic-appointments >/dev/null
aws_local dynamodb create-table --table-name clinic-appointments \
  --attribute-definitions AttributeName=patientId,AttributeType=S AttributeName=apptDate,AttributeType=S AttributeName=severity,AttributeType=N \
  --key-schema AttributeName=patientId,KeyType=HASH AttributeName=apptDate,KeyType=RANGE \
  --local-secondary-indexes \
  '[{"IndexName":"severity-index","KeySchema":[{"AttributeName":"patientId","KeyType":"HASH"},{"AttributeName":"severity","KeyType":"RANGE"}],"Projection":{"ProjectionType":"ALL"}}]' \
  --billing-mode PAY_PER_REQUEST >/dev/null

# 3. restore the items
python3 - <<'PY'
import json, subprocess, os
items = json.load(open("appointments-dump.json"))["Items"]
for item in items:
    subprocess.run(["aws", "--endpoint-url", os.environ["AWS_ENDPOINT_URL"], "dynamodb", "put-item",
                    "--table-name", "clinic-appointments", "--item", json.dumps(item)], check=True,
                   stdout=subprocess.DEVNULL)
PY

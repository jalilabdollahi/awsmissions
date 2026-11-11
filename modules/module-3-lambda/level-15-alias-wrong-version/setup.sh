#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local iam create-role --role-name tax-calculator-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

# One real release per version: the behaviour differs, so the right version is observable.
cat > "$stage/calc.py" <<'PY'
RATES = {"default": 0.19}
LABEL = "2023-rates"

def handler(event, context):
    rate = RATES.get(event.get("category"), RATES["default"])
    return {"tax": round(event["amount"] * rate, 2), "calc": LABEL}
PY
(cd "$stage" && zip -q v1.zip calc.py)
aws_local lambda create-function --function-name tax-calculator \
  --runtime python3.12 --handler calc.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/tax-calculator-role" \
  --zip-file "fileb://$stage/v1.zip" >/dev/null
aws_local lambda publish-version --function-name tax-calculator \
  --description "2023 flat 19% rate - superseded" >/dev/null

cat > "$stage/calc.py" <<'PY'
RATES = {"default": 0.19, "books": 0.07}
LABEL = "2024-rates"

def handler(event, context):
    rate = RATES.get(event.get("category"), RATES["default"])
    return {"tax": round(event["amount"] * rate, 2), "calc": LABEL}
PY
(cd "$stage" && zip -q v2.zip calc.py)
aws_local lambda update-function-code --function-name tax-calculator --zip-file "fileb://$stage/v2.zip" >/dev/null
aws_local lambda publish-version --function-name tax-calculator \
  --description "2024 rates incl. 7% books rate - APPROVED by finance 2024-01-15" >/dev/null

cat > "$stage/calc.py" <<'PY'
import math

RATES = {"default": 0.19, "books": 0.07}
LABEL = "nickel-rounding-experiment"

def handler(event, context):
    rate = RATES.get(event.get("category"), RATES["default"])
    raw = event["amount"] * rate
    return {"tax": round(math.ceil(raw * 20) / 20, 2), "calc": LABEL}
PY
(cd "$stage" && zip -q v3.zip calc.py)
aws_local lambda update-function-code --function-name tax-calculator --zip-file "fileb://$stage/v3.zip" >/dev/null
aws_local lambda publish-version --function-name tax-calculator \
  --description "EXPERIMENT: rounds tax up to 5 cents - NOT approved, staging trial only" >/dev/null

aws_local lambda create-alias --function-name tax-calculator --name staging --function-version 3 >/dev/null
# A typo in the promotion script: there is no version 5.
aws_local lambda create-alias --function-name tax-calculator --name prod --function-version 5 >/dev/null

echo "Alias prod points at a version that does not exist."

#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

# Three layer versions are built as real zips: python/<package>/...
python3 - "$stage" <<'PY'
import sys, zipfile

out = sys.argv[1]

def layer(name, files):
    with zipfile.ZipFile(f"{out}/{name}.zip", "w") as z:
        for path, body in files.items():
            z.writestr(path, body)

RULES_V1 = '''HIGH_RISK = {"BR", "NG"}

def score(txn):
    points = 10
    if txn["amount"] > 500:
        points += 30
    if txn["country"] in HIGH_RISK:
        points += 20
    return points
'''
RULES_V2 = '''HIGH_RISK = {"BR", "NG", "RU"}

def velocity_penalty(count):
    return max(0, count - 3) * 5

def score(txn):
    points = 10
    if txn["amount"] > 500:
        points += 30
    if txn["country"] in HIGH_RISK:
        points += 20
    return points + velocity_penalty(txn["txns_last_hour"])
'''
layer("riskkit-v1", {"python/riskkit/__init__.py": "", "python/riskkit/rules.py": RULES_V1})
layer("riskkit-v2", {"python/riskkit/__init__.py": "", "python/riskkit/rules.py": RULES_V2})
layer("tracekit", {"python/tracekit.py": 'import hashlib, json\n\ndef trace_id(obj):\n    digest = hashlib.sha1(json.dumps(obj, sort_keys=True).encode()).hexdigest()\n    return "tk-" + digest[:10]\n'})
PY

aws_local lambda publish-layer-version --layer-name riskkit-core --description "legacy rules, pre-2024 (deprecated)" \
  --compatible-runtimes python3.12 --zip-file "fileb://$stage/riskkit-v1.zip" >/dev/null
aws_local lambda publish-layer-version --layer-name riskkit-core --description "2024 ruleset: velocity checks, RU added" \
  --compatible-runtimes python3.12 --zip-file "fileb://$stage/riskkit-v2.zip" >/dev/null
aws_local lambda publish-layer-version --layer-name tracekit-logging --description "trace id helper" \
  --compatible-runtimes python3.12 --zip-file "fileb://$stage/tracekit.zip" >/dev/null

aws_local iam create-role --role-name txn-scorer-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null

(cd "$MISSION_DIR/workspace" && zip -q "$stage/scorer.zip" scorer.py)
aws_local lambda create-function --function-name txn-scorer \
  --runtime python3.12 --handler scorer.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/txn-scorer-role" \
  --layers "arn:aws:lambda:us-east-1:${ACCOUNT_ID}:layer:riskkit-core:1" \
           "arn:aws:lambda:us-east-1:${ACCOUNT_ID}:layer:tracekit-logging:1" \
  --zip-file "fileb://$stage/scorer.zip" >/dev/null

echo "txn-scorer is wired to riskkit-core:1, an older layer version than the 2024 ruleset."

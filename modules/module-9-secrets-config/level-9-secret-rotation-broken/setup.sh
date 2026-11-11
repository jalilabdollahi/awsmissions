#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cat > "$work/rotator.py" <<'PY'
def handler(event, context):
    # Stub rotator: the rotation steps are not what this mission is about.
    print(event.get("Step"))
    return "ok"
PY
python3 - "$work" <<'PY'
import sys, zipfile
work = sys.argv[1]
with zipfile.ZipFile(work + "/rotator.zip", "w") as z:
    z.write(work + "/rotator.py", "rotator.py")
PY

role="arn:aws:iam::${ACCOUNT_ID}:role/pelican-rotation-exec"
for fn in pelican-rotate-orders-db-v1 pelican-rotate-orders-db; do
  aws_local lambda create-function --function-name "$fn" --runtime python3.12 \
    --handler rotator.handler --zip-file "fileb://$work/rotator.zip" --role "$role" >/dev/null
done

aws_local secretsmanager create-secret --name pelican/orders-db/password \
  --description "Orders database master password" \
  --secret-string '{"username":"orders_admin","password":"Heron-Quill-5521"}' >/dev/null

# Rotation was once configured against the v1 rotator, rarely (every 90 days)...
aws_local secretsmanager rotate-secret --secret-id pelican/orders-db/password \
  --rotation-lambda-arn "arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:pelican-rotate-orders-db-v1" \
  --rotation-rules AutomaticallyAfterDays=90 --no-rotate-immediately >/dev/null
# ...and then v1 was decommissioned.
aws_local lambda delete-function --function-name pelican-rotate-orders-db-v1

echo "Rotation still points at a function that no longer exists."

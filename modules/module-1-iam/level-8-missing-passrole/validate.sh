#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

build="$(mktemp -d)"
trap 'rm -rf "$build"; aws_local lambda delete-function --function-name kestrel-promo-check >/dev/null 2>&1 || true; aws_local lambda delete-function --function-name kestrel-sneaky >/dev/null 2>&1 || true' EXIT
(cd "$build" && printf 'def handler(e, c):\n    return {"ok": True}\n' > lambda_function.py && python3 -c "
import zipfile
z = zipfile.ZipFile('fn.zip', 'w'); z.write('lambda_function.py'); z.close()")

aws_local lambda delete-function --function-name kestrel-promo-check >/dev/null 2>&1 || true
aws_local lambda delete-function --function-name kestrel-sneaky >/dev/null 2>&1 || true

create_as_releaser() {
  aws_as_user kestrel-releaser lambda create-function --function-name "$1" \
    --runtime python3.12 --handler lambda_function.handler \
    --role "arn:aws:iam::${ACCOUNT_ID}:role/$2" --zip-file "fileb://$build/fn.zip" 2>&1
}

if ! out="$(create_as_releaser kestrel-promo-check promo-fn-role)"; then
  echo "Deploying a function with promo-fn-role as kestrel-releaser still fails:"
  echo "  $(printf '%s' "$out" | tail -1)"
  echo "Creating a function is not the same as being allowed to hand a role to it."
  exit 1
fi

if out="$(create_as_releaser kestrel-sneaky platform-admin-role)"; then
  echo "kestrel-releaser can now create a function that runs as platform-admin-role. That is a privilege escalation path."
  echo "Limit the pass permission to the one role the pipeline needs."
  exit 1
fi

echo "The pipeline can deploy with promo-fn-role and is blocked from platform-admin-role."

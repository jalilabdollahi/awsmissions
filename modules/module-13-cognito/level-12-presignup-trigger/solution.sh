#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Fix the two bugs in the player's copy of the function.
python3 - <<'PY'
src = open("presignup.py").read()
src = src.replace('domain = email.split("@")[1]', 'domain = email.split("@")[1].lower()')
src = src.replace("        event[\"response\"][\"autoVerifyEmail\"] = True\n        return\n",
                  "        event[\"response\"][\"autoVerifyEmail\"] = True\n        return event\n")
open("presignup.py", "w").write(src)
PY

rm -f function.zip
zip -q function.zip presignup.py
aws_local lambda update-function-code --function-name brightpath-presignup \
  --zip-file fileb://function.zip >/dev/null
# Wait until the new code is live before returning.
wait_for "function update to finish" 60 bash -c \
  "[ \"\$(aws --endpoint-url=$AWS_ENDPOINT_URL lambda get-function-configuration --function-name brightpath-presignup --query LastUpdateStatus --output text)\" != InProgress ]"

#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='cobalt-tenants'].Id | [0]" --output text)"
CLAIMS_ARN="$(aws_local lambda get-function-configuration --function-name cobalt-claims \
  --query FunctionArn --output text)"
WELCOME_ARN="$(aws_local lambda get-function-configuration --function-name cobalt-welcome \
  --query FunctionArn --output text)"

# 1. The refactor read the wrong attribute name.
sed 's/custom:tenant_id/custom:tenant/' claims.py > claims.fixed && mv claims.fixed claims.py
rm -f claims.zip
zip -q claims.zip claims.py
aws_local lambda update-function-code --function-name cobalt-claims --zip-file fileb://claims.zip >/dev/null
wait_for "function update to finish" 60 bash -c \
  "[ \"\$(aws --endpoint-url=$AWS_ENDPOINT_URL lambda get-function-configuration --function-name cobalt-claims --query LastUpdateStatus --output text)\" != InProgress ]"

# 2. Re-attach the claims trigger next to the welcome trigger (the config is replaced as a whole).
aws_local cognito-idp update-user-pool --user-pool-id "$POOL_ID" \
  --policies 'PasswordPolicy={MinimumLength=10,RequireUppercase=true,RequireLowercase=true,RequireNumbers=true,RequireSymbols=false}' \
  --lambda-config "PreTokenGeneration=$CLAIMS_ARN,PostConfirmation=$WELCOME_ARN"

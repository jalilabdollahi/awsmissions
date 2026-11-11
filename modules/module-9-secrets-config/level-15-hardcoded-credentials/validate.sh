#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

cfg="$(aws_local lambda get-function-configuration --function-name nimbus-exporter --output json 2>/dev/null || true)"
if [ -z "$cfg" ]; then
  echo "The function nimbus-exporter no longer exists; fix it, do not delete it."
  exit 1
fi

vars="$(printf '%s' "$cfg" | jq -c '.Environment.Variables // {}')"
if printf '%s' "$vars" | jq -e 'has("AWS_ACCESS_KEY_ID") or has("AWS_SECRET_ACCESS_KEY") or has("AWS_SESSION_TOKEN")' >/dev/null; then
  echo "The function's environment still contains AWS credentials."
  exit 1
fi
if [ "$(printf '%s' "$vars" | jq -r '.APP_ENV // empty')" != "prod" ] || \
   [ "$(printf '%s' "$vars" | jq -r '.TOKEN_SECRET_ID // empty')" != "nimbus/exporter/api-token" ]; then
  echo "The function lost its APP_ENV or TOKEN_SECRET_ID setting. Changing the environment replaces all variables, so keep the ones it needs."
  exit 1
fi

role_arn="$(printf '%s' "$cfg" | jq -r '.Role')"
role_name="${role_arn##*/}"
if [ "$role_name" = "nimbus-bare" ]; then
  echo "The function still runs as nimbus-bare, which has no permissions. Give it a role that may read its secret."
  exit 1
fi
if ! trust="$(aws_local iam get-role --role-name "$role_name" --query Role.AssumeRolePolicyDocument --output json 2>/dev/null)"; then
  echo "The function's role $role_name does not exist."
  exit 1
fi
if ! printf '%s' "$trust" | jq -e '[.Statement[] | select(.Effect=="Allow") | .Principal.Service] | flatten | index("lambda.amazonaws.com")' >/dev/null; then
  echo "Role $role_name does not trust lambda.amazonaws.com, so Lambda cannot assume it."
  exit 1
fi

secret_arn="$(aws_local secretsmanager describe-secret --secret-id nimbus/exporter/api-token --query ARN --output text)"
other_arn="$(aws_local secretsmanager describe-secret --secret-id nimbus/billing/master --query ARN --output text)"
decide() {
  aws_local iam simulate-principal-policy --policy-source-arn "arn:aws:iam::${ACCOUNT_ID}:role/$role_name" \
    --action-names secretsmanager:GetSecretValue --resource-arns "$1" \
    --query 'EvaluationResults[0].EvalDecision' --output text 2>/dev/null || true
}
if [ "$(decide "$secret_arn")" != "allowed" ]; then
  echo "Role $role_name is not allowed to read nimbus/exporter/api-token."
  exit 1
fi
if [ "$(decide "$other_arn")" = "allowed" ]; then
  echo "Role $role_name can read other secrets too (nimbus/billing/master). Limit it to the exporter's token."
  exit 1
fi

# The leaked key must be unusable.
active="$(aws_local iam list-access-keys --user-name nimbus-ci \
  --query "length(AccessKeyMetadata[?Status=='Active'])" --output text)"
if [ "$active" != "0" ]; then
  echo "The access key that was in the function's environment is still active. Anything that has seen it can still use it."
  exit 1
fi

echo "nimbus-exporter now uses a least-privilege execution role, carries no keys, and the leaked key is dead."

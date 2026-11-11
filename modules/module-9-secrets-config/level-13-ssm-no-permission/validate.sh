#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/kiln-task"

read_as_task() {
  aws_as_role "$ROLE_ARN" kiln-deployer "" ssm get-parameter --name "$1" --with-decryption \
    --query Parameter.Value --output text 2>&1
}

set +e
queue="$(read_as_task /kiln/prod/queue-url)"
rc=$?
set -e
if [ "$rc" -eq 98 ]; then
  echo "kiln-deployer can no longer assume kiln-task; leave the trust policy alone."
  exit 1
fi
if [ "$rc" -ne 0 ]; then
  echo "kiln-task cannot read /kiln/prod/queue-url: $(printf '%s' "$queue" | tail -1)"
  exit 1
fi
if [ "$queue" != "https://queues.kiln.internal/matchmaking" ]; then
  echo "The role read an unexpected queue URL."
  exit 1
fi

pw="$(read_as_task /kiln/prod/db-password)" || {
  echo "kiln-task cannot read /kiln/prod/db-password: $(printf '%s' "$pw" | tail -1)"
  exit 1
}
if [ "$pw" != "Basalt-Ember-318" ]; then
  echo "The role read an unexpected password value."
  exit 1
fi

# SecureStrings also need kms:Decrypt on their key (an IAM-level check).
kiln_key="$(aws_local kms describe-key --key-id alias/kiln-config --query KeyMetadata.Arn --output text)"
other_key="$(aws_local kms describe-key --key-id alias/aws/ssm --query KeyMetadata.Arn --output text)"
decision() {
  aws_local iam simulate-principal-policy --policy-source-arn "$ROLE_ARN" \
    --action-names kms:Decrypt --resource-arns "$1" \
    --query 'EvaluationResults[0].EvalDecision' --output text 2>/dev/null || true
}
if [ "$(decision "$kiln_key")" != "allowed" ]; then
  echo "kiln-task may read the parameter, but IAM does not let it kms:Decrypt with the key behind alias/kiln-config. In real AWS the SecureString read would fail."
  exit 1
fi
if [ "$(decision "$other_key")" = "allowed" ]; then
  echo "kiln-task may decrypt with other keys too. Scope kms:Decrypt to the Kiln configuration key only."
  exit 1
fi

if read_as_task /kiln/dev/queue-url >/dev/null 2>&1; then
  echo "kiln-task can read /kiln/dev/... too. Production tasks should only see /kiln/prod/."
  exit 1
fi
if read_as_task /kiln-admin/root-token >/dev/null 2>&1; then
  echo "kiln-task can read /kiln-admin/... The pattern is too broad; /kiln/prod/* must not match /kiln-admin."
  exit 1
fi

echo "kiln-task reads both production parameters, decrypts only with its own key, and sees nothing else."

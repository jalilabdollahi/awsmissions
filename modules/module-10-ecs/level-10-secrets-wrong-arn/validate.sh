#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TD=$(aws_local ecs describe-services --cluster cedar --services ledger-sync --query 'services[0].taskDefinition' --output text 2>/dev/null || true)
if [ -z "$TD" ] || [ "$TD" = "None" ]; then
  echo "The ledger-sync service is missing."
  exit 1
fi
SECRET=$(aws_local secretsmanager get-secret-value --secret-id cedar/db-credentials --query SecretString --output text 2>/dev/null || true)
if [ -z "$SECRET" ]; then
  echo "The secret cedar/db-credentials has been removed. It was right; the task definition was wrong."
  exit 1
fi
WANT_USER=$(printf '%s' "$SECRET" | python3 -c 'import json,sys; print(json.load(sys.stdin)["username"])')
WANT_PASS=$(printf '%s' "$SECRET" | python3 -c 'import json,sys; print(json.load(sys.stdin)["password"])')

received() {
  local arn id
  for arn in $(aws_local ecs list-tasks --cluster cedar --service-name ledger-sync --desired-status RUNNING --query 'taskArns[]' --output text); do
    id=${arn##*/}
    [ "$(docker exec "floci-aws-${AWSMISSIONS_NAMESPACE}-ecs-$id-sync" printenv DB_USER 2>/dev/null || true)" = "$WANT_USER" ] || continue
    [ "$(docker exec "floci-aws-${AWSMISSIONS_NAMESPACE}-ecs-$id-sync" printenv DB_PASSWORD 2>/dev/null || true)" = "$WANT_PASS" ] && return 0
  done
  return 1
}
if ! wait_for "a ledger-sync task holding the secret values" 25 received; then
  LAST=$(aws_local ecs list-tasks --cluster cedar --desired-status STOPPED --query 'taskArns[0]' --output text 2>/dev/null || true)
  REASON=""
  if [ -n "$LAST" ] && [ "$LAST" != "None" ]; then
    REASON=$(aws_local ecs describe-tasks --cluster cedar --tasks "$LAST" --query 'tasks[0].stoppedReason' --output text | cut -c1-200)
  fi
  echo "No running ledger-sync task has DB_USER/DB_PASSWORD from cedar/db-credentials yet. Latest stopped task: ${REASON:-none}"
  exit 1
fi
echo "ledger-sync is running and its container received the credentials from cedar/db-credentials."

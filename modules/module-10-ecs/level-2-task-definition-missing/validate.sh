#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SVC=$(aws_local ecs describe-services --cluster harbor --services harbor-web --query 'services[0].[status,desiredCount,taskDefinition]' --output text 2>/dev/null || true)
STATUS=$(printf '%s' "$SVC" | awk '{print $1}')
DESIRED=$(printf '%s' "$SVC" | awk '{print $2}')
TD=$(printf '%s' "$SVC" | awk '{print $3}')
if [ "$STATUS" != "ACTIVE" ]; then
  echo "The service harbor-web does not exist in the harbor cluster yet."
  exit 1
fi
case "$TD" in
  */harbor-web:*) ;;
  *) echo "harbor-web runs task definition $TD, not a harbor-web revision."; exit 1;;
esac
if [ "$DESIRED" != "2" ]; then
  echo "harbor-web wants $DESIRED task(s); the deploy calls for 2."
  exit 1
fi

serving() {
  local good=0 arn id
  for arn in $(aws_local ecs list-tasks --cluster harbor --service-name harbor-web --desired-status RUNNING --query 'taskArns[]' --output text); do
    id=${arn##*/}
    if docker exec "floci-aws-${AWSMISSIONS_NAMESPACE}-ecs-$id-web" wget -q -O /dev/null http://127.0.0.1:80/ 2>/dev/null; then
      good=$((good + 1))
    fi
  done
  [ "$good" -ge 2 ]
}
if ! wait_for "two harbor-web tasks answering on port 80" 60 serving; then
  echo "harbor-web is ACTIVE but fewer than two of its tasks are running and answering HTTP on port 80."
  exit 1
fi
echo "harbor-web has two tasks serving HTTP."

#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

read -r STATUS DESIRED TD <<EOT
$(aws_local ecs describe-services --cluster sundial --services sundial-api --query 'services[0].[status,desiredCount,taskDefinition]' --output text 2>/dev/null || echo "MISSING 0 none")
EOT
if [ "$STATUS" != "ACTIVE" ]; then
  echo "The sundial-api service no longer exists; scale the existing one back up instead of recreating it."
  exit 1
fi
case "$TD" in
  *sundial-api:1) ;;
  *) echo "sundial-api now runs $TD; the task definition was supposed to stay at revision 1."; exit 1;;
esac
if [ "$DESIRED" != "2" ]; then
  echo "sundial-api is configured for $DESIRED task(s). Production keeps two."
  exit 1
fi
answering() {
  local n=0 arn
  for arn in $(aws_local ecs list-tasks --cluster sundial --service-name sundial-api --desired-status RUNNING --query 'taskArns[]' --output text); do
    docker exec "floci-aws-ecs-${arn##*/}-api" wget -q -O /dev/null http://127.0.0.1:80/ 2>/dev/null && n=$((n + 1))
  done
  [ "$n" -ge 2 ]
}
if ! wait_for "two sundial-api tasks answering on port 80" 60 answering; then
  echo "desiredCount is 2, but fewer than two tasks are running and serving HTTP yet."
  exit 1
fi
echo "sundial-api has two tasks up and answering. Bookings are back."

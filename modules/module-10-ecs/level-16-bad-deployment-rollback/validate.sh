#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

read -r STATUS TD <<EOT
$(aws_local ecs describe-services --cluster tidepool --services tidepool-web --query 'services[0].[status,taskDefinition]' --output text 2>/dev/null || echo "MISSING none")
EOT
if [ "$STATUS" != "ACTIVE" ]; then
  echo "The tidepool-web service is gone; roll it back instead of recreating it."
  exit 1
fi
CRASH=$(aws_local ecs describe-task-definition --task-definition "$TD" \
  --query "taskDefinition.containerDefinitions[0].command" --output text 2>/dev/null || true)
case "$CRASH" in
  *migration*) echo "The service still runs $TD, the revision whose migration crashes. Move it onto a revision that works."; exit 1;;
esac
serving() {
  local n=0 arn
  for arn in $(aws_local ecs list-tasks --cluster tidepool --service-name tidepool-web --desired-status RUNNING --query 'taskArns[]' --output text); do
    [ "$(aws_local ecs describe-tasks --cluster tidepool --tasks "$arn" --query 'tasks[0].taskDefinitionArn' --output text)" = "$TD" ] || continue
    docker exec "floci-aws-${AWSMISSIONS_NAMESPACE}-ecs-${arn##*/}-web" wget -q -O /dev/null http://127.0.0.1:80/ 2>/dev/null && n=$((n + 1))
  done
  [ "$n" -ge 2 ]
}
DESIRED=$(aws_local ecs describe-services --cluster tidepool --services tidepool-web --query 'services[0].desiredCount' --output text)
if [ "$DESIRED" != "2" ]; then
  echo "tidepool-web is set to $DESIRED task(s); production runs two."
  exit 1
fi
if ! wait_for "two tidepool-web tasks answering HTTP on the good revision" 60 serving; then
  echo "The service points at $TD, but fewer than two of its tasks are running and answering on port 80."
  exit 1
fi
CB=$(aws_local ecs describe-services --cluster tidepool --services tidepool-web \
  --query 'services[0].deploymentConfiguration.deploymentCircuitBreaker.[enable,rollback]' --output text)
if [ "$CB" != "True	True" ] && [ "$CB" != "true	true" ]; then
  echo "Service is back, but the deployment circuit breaker with rollback is not enabled (enable/rollback: $CB). The next bad deploy would hurt again."
  exit 1
fi
echo "tidepool-web is serving from a good revision and future bad deploys will roll back automatically."

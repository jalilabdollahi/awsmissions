#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TD=$(aws_local ecs describe-services --cluster pulse --services pulse-ingest --query 'services[0].taskDefinition' --output text 2>/dev/null || true)
if [ -z "$TD" ] || [ "$TD" = "None" ]; then
  echo "The pulse-ingest service has disappeared; fix it rather than recreating it."
  exit 1
fi
ENVJSON=$(aws_local ecs describe-task-definition --task-definition "$TD" --query 'taskDefinition.containerDefinitions[0].environment' --output json)
MODE=$(ENVJSON="$ENVJSON" python3 -c '
import json, os
print(next((e["value"] for e in json.loads(os.environ["ENVJSON"]) if e["name"] == "APP_MODE"), ""))
')
if [ -z "$MODE" ]; then
  echo "The revision pulse-ingest runs ($TD) still has no APP_MODE variable. A task definition is immutable: register a new revision and update the service."
  exit 1
fi
if [ "$MODE" != "worker" ]; then
  echo "APP_MODE is '$MODE'. pulse-ingest consumes a queue; the startup script tells you which mode that is."
  exit 1
fi
stays_up() {
  local arn id
  for arn in $(aws_local ecs list-tasks --cluster pulse --service-name pulse-ingest --desired-status RUNNING --query 'taskArns[]' --output text); do
    id=${arn##*/}
    [ "$(aws_local ecs describe-tasks --cluster pulse --tasks "$arn" --query 'tasks[0].taskDefinitionArn' --output text)" = "$TD" ] || continue
    [ "$(docker exec "floci-aws-ecs-$id-ingest" printenv APP_MODE 2>/dev/null || true)" = worker ] && return 0
  done
  return 1
}
if ! wait_for "a pulse-ingest worker task" 60 stays_up; then
  echo "APP_MODE is set in the new revision, but no task of that revision is running yet."
  exit 1
fi
sleep 6
if ! stays_up; then
  echo "The worker started but exited again. Check the log group /ecs/pulse-ingest."
  exit 1
fi
if ! aws_local logs filter-log-events --log-group-name /ecs/pulse-ingest --filter-pattern '"worker started"' --query 'events[0].message' --output text | grep -q started; then
  echo "The worker task is up but its start-up line never reached /ecs/pulse-ingest."
  exit 1
fi
echo "pulse-ingest is running as a worker and has stopped crash-looping."

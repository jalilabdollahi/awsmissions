#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

CL=ledger-prod
SVC=ledger-web
bad=0
echo "ledger-web triage (INC-6120)"

svc_json="$(aws_local ecs describe-services --cluster "$CL" --services "$SVC" --query 'services[0]' --output json 2>/dev/null || echo null)"
if [ "$svc_json" = "null" ] || [ "$(printf '%s' "$svc_json" | jq -r '.status')" != "ACTIVE" ]; then
  echo "The ledger-web service is gone. Repair it; do not delete it."
  exit 1
fi
TD="$(printf '%s' "$svc_json" | jq -r '.taskDefinition')"
td_json="$(aws_local ecs describe-task-definition --task-definition "$TD" --query taskDefinition --output json)"

# Constraints that must hold.
if [ "$(printf '%s' "$td_json" | jq -r '[.containerDefinitions[] | select(.name == "web")] | length')" != "1" ]; then
  echo "The service's task definition has no container named 'web'."
  exit 1
fi
cmd="$(printf '%s' "$td_json" | jq -r '[.containerDefinitions[] | select(.name == "web") | ((.entryPoint // []) + (.command // []))[]] | join(" ")')"
case "$cmd" in
  *DB_HOST*) ;;
  *) echo "The DB_HOST guard in the container wrapper was removed. It has to stay; supply the variable instead."; exit 1 ;;
esac

# Symptom 1: the container's configuration.
dbhost="$(printf '%s' "$td_json" | jq -r '[.containerDefinitions[] | select(.name == "web") | .environment[]? | select(.name == "DB_HOST") | .value] | first // ""')"
if [ "$dbhost" = "ledger-db.internal" ]; then
  echo "[ok]    symptom 1  the web container receives DB_HOST=ledger-db.internal"
else
  echo "[FAULT] symptom 1  the web container's startup wrapper will not find the setting it requires (DB_HOST='${dbhost}')"
  bad=$((bad + 1))
fi

# Symptom 2: can a task of the service's task definition start from its image?
probe="$(aws_local ecs run-task --cluster "$CL" --task-definition "$TD" --launch-type FARGATE --started-by awsm-probe \
  --network-configuration 'awsvpcConfiguration={subnets=[subnet-default-us-east-1-a]}' \
  --query 'tasks[0].taskArn' --output text 2>/dev/null || true)"
state=""
if [ -n "$probe" ] && [ "$probe" != "None" ]; then
  i=0
  while [ "$i" -lt 25 ]; do
    state="$(aws_local ecs describe-tasks --cluster "$CL" --tasks "$probe" --query 'tasks[0].lastStatus' --output text 2>/dev/null || true)"
    [ "$state" = "RUNNING" ] || [ "$state" = "STOPPED" ] && break
    sleep 1; i=$((i + 1))
  done
  if [ "$state" = "RUNNING" ]; then sleep 5; state="$(aws_local ecs describe-tasks --cluster "$CL" --tasks "$probe" --query 'tasks[0].lastStatus' --output text)"; fi
fi
if [ "$state" = "RUNNING" ]; then
  echo "[ok]    symptom 2  a test task from the service's task definition starts and stays up"
else
  reason="$(aws_local ecs describe-tasks --cluster "$CL" --tasks "${probe:-none}" --query 'tasks[0].[stoppedReason, containers[0].exitCode, containers[0].reason]' --output text 2>/dev/null | cut -c1-170 || true)"
  echo "[FAULT] symptom 2  a test task from the service's task definition does not stay up: ${reason:-no task was created}"
  bad=$((bad + 1))
fi
if [ -n "$probe" ] && [ "$probe" != "None" ]; then
  aws_local ecs stop-task --cluster "$CL" --task "$probe" >/dev/null 2>&1 || true
fi

# Symptom 3: is the service asked to run enough of them?
want="$(printf '%s' "$svc_json" | jq -r '.desiredCount')"
if [ "$want" -lt 2 ]; then
  echo "[FAULT] symptom 3  the service wants $want task(s); month-end close needs 2"
  bad=$((bad + 1))
else
  echo "[ok]    symptom 3  the service wants $want tasks"
fi

if [ "$bad" -gt 0 ]; then
  echo "$bad symptom(s) remain."
  exit 1
fi

running() {
  [ "$(aws_local ecs describe-services --cluster "$CL" --services "$SVC" --query 'services[0].runningCount' --output text)" -ge 2 ]
}
if ! wait_for "two running tasks" 50 running; then
  echo "Settings look right, but the service does not reach 2 running tasks within 50s. Read its events: aws ecs describe-services."
  exit 1
fi
sleep 6
n="$(aws_local ecs list-tasks --cluster "$CL" --service-name "$SVC" --desired-status RUNNING --query 'length(taskArns)' --output text)"
if [ "$n" -lt 2 ]; then
  echo "Tasks started but did not stay up: only $n still running after a few seconds."
  exit 1
fi
echo "ledger-web has $n tasks running and stable. Month-end close can proceed."

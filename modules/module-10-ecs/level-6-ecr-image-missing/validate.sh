#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

APPROVED=$(aws_local ssm get-parameter --name /hearth/web/approved-image --query Parameter.Value --output text 2>/dev/null || true)
if [ -z "$APPROVED" ]; then
  echo "The approved-image parameter is gone; it is the source of truth and must stay untouched."
  exit 1
fi
serving() {
  local arn id image
  for arn in $(aws_local ecs list-tasks --cluster hearth --family hearth-web --desired-status RUNNING --query 'taskArns[]' --output text); do
    id=${arn##*/}
    image=$(docker inspect -f '{{.Image}}' "floci-aws-ecs-$id-web" 2>/dev/null || true)
    [ -n "$image" ] && [ "$image" = "$(docker image inspect -f '{{.Id}}' "$APPROVED" 2>/dev/null || echo none)" ] || continue
    docker exec "floci-aws-ecs-$id-web" wget -q -O /dev/null http://127.0.0.1:80/ 2>/dev/null && return 0
  done
  return 1
}
if ! wait_for "a hearth-web task from the approved image" 20 serving; then
  LAST=$(aws_local ecs list-tasks --cluster hearth --desired-status STOPPED --query 'taskArns[-1]' --output text 2>/dev/null || true)
  if [ -n "$LAST" ] && [ "$LAST" != "None" ]; then
    echo "No running hearth-web task uses the approved image ($APPROVED). Latest stopped task said: $(aws_local ecs describe-tasks --cluster hearth --tasks "$LAST" --query 'tasks[0].stoppedReason' --output text | cut -c1-160)"
  else
    echo "No running hearth-web task uses the approved image ($APPROVED)."
  fi
  exit 1
fi
echo "hearth-web is serving from the approved image $APPROVED."

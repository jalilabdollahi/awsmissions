#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TD=$(aws_local ecs describe-services --cluster pixelmill --services resizer --query 'services[0].taskDefinition' --output text 2>/dev/null || true)
ROLE_ARN=$(aws_local ecs describe-task-definition --task-definition "$TD" --query 'taskDefinition.taskRoleArn' --output text 2>/dev/null || true)
if [ "$ROLE_ARN" != "arn:aws:iam::${ACCOUNT_ID}:role/pixelmill-task-role" ]; then
  echo "The resizer service no longer runs with pixelmill-task-role (task role is: ${ROLE_ARN:-none}). Fix the role's permissions instead of swapping roles."
  exit 1
fi

can() {  # action resource -> prints decision
  aws_local iam simulate-principal-policy --policy-source-arn "$ROLE_ARN" --action-names "$1" --resource-arns "$2" \
    --query 'EvaluationResults[0].EvalDecision' --output text
}
want_allowed() { [ "$(can "$1" "$2")" = allowed ] || { echo "$3"; exit 1; }; }
want_denied()  { [ "$(can "$1" "$2")" != allowed ] || { echo "$3"; exit 1; }; }

want_allowed s3:GetObject  arn:aws:s3:::pixelmill-uploads/photos/cat.jpg "The role still cannot GetObject from pixelmill-uploads. Object-level actions need an object ARN (bucket/key or bucket/*), not the bucket ARN."
want_allowed s3:ListBucket arn:aws:s3:::pixelmill-uploads "The role cannot list pixelmill-uploads. ListBucket applies to the bucket ARN itself."
want_allowed s3:PutObject  arn:aws:s3:::pixelmill-thumbs/cat-128.jpg "The role still cannot PutObject into pixelmill-thumbs (object ARNs need the /* part)."
want_denied  s3:PutObject  arn:aws:s3:::pixelmill-uploads/photos/cat.jpg "The role can overwrite originals in pixelmill-uploads. It should only read there."
want_denied  s3:DeleteObject arn:aws:s3:::pixelmill-uploads/photos/cat.jpg "The role can delete objects. The resizer never needs to."
want_denied  s3:GetObject  arn:aws:s3:::pixelmill-billing/invoice-2025.csv "The role can read pixelmill-billing. That bucket is off limits to the resizer."
want_denied  s3:PutObject  arn:aws:s3:::pixelmill-billing/x "The role can write to pixelmill-billing."

alive() {
  local arn id
  for arn in $(aws_local ecs list-tasks --cluster pixelmill --service-name resizer --desired-status RUNNING --query 'taskArns[]' --output text); do
    id=${arn##*/}
    docker inspect -f '{{.State.Running}}' "floci-aws-${AWSMISSIONS_NAMESPACE}-ecs-$id-resizer" 2>/dev/null | grep -q true && return 0
  done
  return 1
}
if ! wait_for "the resizer task" 40 alive; then
  echo "Permissions look right, but the resizer service has no running task."
  exit 1
fi
echo "pixelmill-task-role can read uploads, list them and write thumbnails, and nothing more."

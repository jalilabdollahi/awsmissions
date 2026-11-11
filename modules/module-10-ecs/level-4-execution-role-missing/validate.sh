#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TD_ARN=$(aws_local ecs describe-services --cluster payroll --services payroll-api --query 'services[0].taskDefinition' --output text 2>/dev/null || true)
if [ -z "$TD_ARN" ] || [ "$TD_ARN" = "None" ]; then
  echo "The payroll-api service is missing from the payroll cluster."
  exit 1
fi
EXEC=$(aws_local ecs describe-task-definition --task-definition "$TD_ARN" --query 'taskDefinition.executionRoleArn' --output text)
if [ -z "$EXEC" ] || [ "$EXEC" = "None" ]; then
  echo "The revision payroll-api runs ($TD_ARN) has no executionRoleArn. Register a new revision that names the execution role and point the service at it."
  exit 1
fi
ROLE=${EXEC##*/}
TRUST=$(aws_local iam get-role --role-name "$ROLE" --query 'Role.AssumeRolePolicyDocument' --output json 2>/dev/null || true)
if [ -z "$TRUST" ]; then
  echo "The task definition names $EXEC, but that role does not exist."
  exit 1
fi
TRUST="$TRUST" python3 -c '
import json, os, sys
doc = json.loads(os.environ["TRUST"])
for st in doc["Statement"]:
    svc = st.get("Principal", {}).get("Service", [])
    svc = [svc] if isinstance(svc, str) else svc
    if st["Effect"] == "Allow" and "ecs-tasks.amazonaws.com" in svc:
        sys.exit(0)
print("Role trust policy does not allow ecs-tasks.amazonaws.com to assume it, so ECS cannot use it as an execution role.")
sys.exit(1)
' || exit 1

sim() {  # action resource
  aws_local iam simulate-principal-policy --policy-source-arn "arn:aws:iam::${ACCOUNT_ID}:role/$ROLE" \
    --action-names "$1" --resource-arns "$2" --query 'EvaluationResults[0].EvalDecision' --output text
}
SECRET_ARN=$(aws_local secretsmanager describe-secret --secret-id payroll/db-password --query ARN --output text)
OTHER_ARN=$(aws_local secretsmanager describe-secret --secret-id payroll/ceo-notes --query ARN --output text)
[ "$(sim secretsmanager:GetSecretValue "$SECRET_ARN")" = allowed ] || { echo "The execution role cannot read secretsmanager:GetSecretValue on payroll/db-password."; exit 1; }
[ "$(sim secretsmanager:GetSecretValue "$OTHER_ARN")" != allowed ] || { echo "The execution role can read every secret (including payroll/ceo-notes). Scope secret access to payroll/db-password only."; exit 1; }
[ "$(sim logs:PutLogEvents "arn:aws:logs:us-east-1:${ACCOUNT_ID}:log-group:/ecs/payroll-api:log-stream:api/api/x")" = allowed ] || { echo "The execution role cannot write log events to /ecs/payroll-api."; exit 1; }
[ "$(sim ecr:GetAuthorizationToken '*')" = allowed ] || { echo "The execution role cannot get a registry auth token (ecr:GetAuthorizationToken), so image pulls would fail."; exit 1; }
[ "$(sim iam:CreateUser '*')" != allowed ] || { echo "The execution role is far too powerful (it may create IAM users). It only needs pull, log and secret access."; exit 1; }

alive() {
  local arn id
  for arn in $(aws_local ecs list-tasks --cluster payroll --service-name payroll-api --desired-status RUNNING --query 'taskArns[]' --output text); do
    id=${arn##*/}
    [ "$(aws_local ecs describe-tasks --cluster payroll --tasks "$arn" --query 'tasks[0].taskDefinitionArn' --output text)" = "$TD_ARN" ] || continue
    docker inspect -f '{{.State.Running}}' "floci-aws-${AWSMISSIONS_NAMESPACE}-ecs-$id-api" 2>/dev/null | grep -q true && return 0
  done
  return 1
}
if ! wait_for "a payroll-api task on the new revision" 60 alive; then
  echo "The service points at the new revision, but no task of that revision is running yet."
  exit 1
fi
echo "payroll-api runs with a scoped execution role ($ROLE) that can pull, log and read only its own secret."

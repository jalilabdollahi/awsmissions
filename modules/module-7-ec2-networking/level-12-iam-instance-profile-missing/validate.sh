#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

IID=$(aws_local ec2 describe-instances --filters Name=tag:Name,Values=ember-api Name=instance-state-name,Values=pending,running \
  --query 'Reservations[0].Instances[0].InstanceId' --output text 2>/dev/null || true)
if [ -z "$IID" ] || [ "$IID" = "None" ]; then
  echo "ember-api is not running; attach the profile to the existing instance."
  exit 1
fi
PROFILE_ARN=$(aws_local ec2 describe-iam-instance-profile-associations --filters Name=instance-id,Values="$IID" \
  --query "IamInstanceProfileAssociations[?State=='associated'||State=='associating'].IamInstanceProfile.Arn|[0]" --output text 2>/dev/null || true)
if [ -z "$PROFILE_ARN" ] || [ "$PROFILE_ARN" = "None" ]; then
  echo "ember-api has no instance profile attached, so the app has no credentials to find."
  exit 1
fi
PROFILE=${PROFILE_ARN##*/}
ROLES=$(aws_local iam get-instance-profile --instance-profile-name "$PROFILE" --query 'InstanceProfile.Roles[].RoleName' --output text)
case " $ROLES " in
  *" ember-app-role "*) ;;
  *) echo "The attached profile ($PROFILE) does not contain ember-app-role; it holds: ${ROLES:-no role}."; exit 1;;
esac

TRUST=$(aws_local iam get-role --role-name ember-app-role --query 'Role.AssumeRolePolicyDocument' --output json)
TRUST="$TRUST" python3 -c '
import json, os, sys
doc = json.loads(os.environ["TRUST"])
ok = False
for st in doc["Statement"]:
    svc = st.get("Principal", {}).get("Service", [])
    svc = [svc] if isinstance(svc, str) else svc
    if st["Effect"] == "Allow" and "ec2.amazonaws.com" in svc:
        ok = True
if not ok:
    print("The profile is attached, but ember-app-role does not trust ec2.amazonaws.com, so EC2 cannot hand the instance credentials for it."); sys.exit(1)
' || exit 1

ARN="arn:aws:iam::${ACCOUNT_ID}:role/ember-app-role"
decision() {  # action resource
  aws_local iam simulate-principal-policy --policy-source-arn "$ARN" --action-names "$1" --resource-arns "$2" \
    --query 'EvaluationResults[0].EvalDecision' --output text
}
if [ "$(decision s3:GetObject arn:aws:s3:::ember-config/app.json)" != "allowed" ]; then
  echo "ember-app-role can no longer read objects in ember-config."
  exit 1
fi
if [ "$(decision s3:PutObject arn:aws:s3:::ember-config/app.json)" = "allowed" ]; then
  echo "ember-app-role can write to ember-config. The app only needs to read its configuration."
  exit 1
fi
if [ "$(decision s3:GetObject arn:aws:s3:::ember-billing/invoice.csv)" = "allowed" ]; then
  echo "ember-app-role can read ember-billing. Keep the role scoped to ember-config."
  exit 1
fi
echo "ember-api carries ember-app-role through an instance profile EC2 may assume, scoped to ember-config."

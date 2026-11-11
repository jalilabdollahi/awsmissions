#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://lumen-homes >/dev/null
seed="$(mktemp)"
trap 'rm -f "$seed"' EXIT
echo 'alice private' > "$seed"
aws_local s3api put-object --bucket lumen-homes --key lumen-alice/notes.txt --body "$seed" >/dev/null
echo 'bob private' > "$seed"
aws_local s3api put-object --bucket lumen-homes --key lumen-bob/notes.txt --body "$seed" >/dev/null

policy_arn="$(aws_local iam create-policy --policy-name home-folders \
  --policy-document "file://$MISSION_DIR/workspace/policy.json" --query Policy.Arn --output text)"
aws_local iam create-group --group-name lumen-staff >/dev/null
aws_local iam attach-group-policy --group-name lumen-staff --policy-arn "$policy_arn"
for u in lumen-alice lumen-bob; do
  aws_local iam create-user --user-name "$u" >/dev/null
  aws_local iam add-user-to-group --group-name lumen-staff --user-name "$u"
done

echo "home-folders is attached to lumen-staff, and nobody can open their own folder."

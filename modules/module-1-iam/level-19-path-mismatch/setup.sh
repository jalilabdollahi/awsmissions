#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local iam create-group --group-name redwood-contractors --path /contractors/ >/dev/null
for u in redwood-kim redwood-lee; do
  aws_local iam create-user --user-name "$u" --path /contractors/ >/dev/null
  aws_local iam add-user-to-group --group-name redwood-contractors --user-name "$u"
done
# Someone who is not a contractor and has a key of their own.
aws_local iam create-user --user-name redwood-staff-ana >/dev/null
aws_local iam create-access-key --user-name redwood-staff-ana >/dev/null

aws_local iam put-group-policy --group-name redwood-contractors --policy-name self-service-keys \
  --policy-document "file://$MISSION_DIR/workspace/policy.json"

echo "redwood-contractors has a self-service policy that worked in the pilot and now matches nobody."

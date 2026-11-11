#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb create-table --table-name crmly-contacts \
  --attribute-definitions AttributeName=tenantId,AttributeType=S AttributeName=contactId,AttributeType=S \
  --key-schema AttributeName=tenantId,KeyType=HASH AttributeName=contactId,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST >/dev/null

c() {
  aws_local dynamodb put-item --table-name crmly-contacts --item \
    "{\"tenantId\":{\"S\":\"$1\"},\"contactId\":{\"S\":\"$2\"},\"fullName\":{\"S\":\"$3\"}}"
}
c acme c-1 "Dana Whitfield"
c acme c-2 "Omar Reyes"
c globex c-1 "Heidi Brandt"
c globex c-2 "Yusuf Demir"

aws_local iam create-user --user-name portal-acme >/dev/null
aws_local iam put-user-policy --user-name portal-acme --policy-name portal-data-access \
  --policy-document "file://$MISSION_DIR/workspace/portal-policy.json"

echo "portal-acme can touch every tenant in crmly-contacts."

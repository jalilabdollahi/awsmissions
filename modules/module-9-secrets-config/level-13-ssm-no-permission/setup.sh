#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

key_id="$(aws_local kms create-key --description "Kiln configuration secrets" \
  --query KeyMetadata.KeyId --output text)"
aws_local kms create-alias --alias-name alias/kiln-config --target-key-id "$key_id"

aws_local ssm put-parameter --name /kiln/prod/queue-url --type String \
  --value "https://queues.kiln.internal/matchmaking" >/dev/null
aws_local ssm put-parameter --name /kiln/prod/db-password --type SecureString \
  --key-id alias/kiln-config --value "Basalt-Ember-318" >/dev/null
aws_local ssm put-parameter --name /kiln/dev/queue-url --type String \
  --value "https://queues.kiln.internal/dev" >/dev/null
aws_local ssm put-parameter --name /kiln-admin/root-token --type SecureString \
  --value "adm-0f9e31" >/dev/null

aws_local iam create-user --user-name kiln-deployer >/dev/null
aws_local iam put-user-policy --user-name kiln-deployer --policy-name assume-task-role \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"arn:aws:iam::${ACCOUNT_ID}:role/kiln-task\"}]}"
aws_local iam create-role --role-name kiln-task \
  --assume-role-policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::${ACCOUNT_ID}:user/kiln-deployer\"},\"Action\":\"sts:AssumeRole\"}]}" >/dev/null
aws_local iam put-role-policy --role-name kiln-task --policy-name kiln-task-config \
  --policy-document "file://$MISSION_DIR/workspace/policy.json"

echo "kiln-task is attached to a policy that does not let it read its configuration."

#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

pool_id() {
  aws_local cognito-idp list-user-pools --max-results 60 \
    --query "UserPools[?Name=='$1'].Id | [0]" --output text 2>/dev/null || true
}
STAFF="$(pool_id fernwood-staff)"
CONTRACTORS="$(pool_id fernwood-contractors)"
if [ -z "$STAFF" ] || [ "$STAFF" = "None" ] || [ -z "$CONTRACTORS" ] || [ "$CONTRACTORS" = "None" ]; then
  echo "One of the pools fernwood-staff / fernwood-contractors is missing. The policy is the thing to fix."
  exit 1
fi
if ! aws_local iam get-user --user-name fernwood-provisioner >/dev/null 2>&1; then
  echo "The IAM user fernwood-provisioner no longer exists."
  exit 1
fi

stamp="$(date +%s)"
newbie="hire-$stamp"
cleanup() {
  aws_local cognito-idp admin-delete-user --user-pool-id "$STAFF" --username "$newbie" >/dev/null 2>&1 || true
  aws_local cognito-idp admin-delete-user --user-pool-id "$CONTRACTORS" --username "intruder-$stamp" >/dev/null 2>&1 || true
}
trap cleanup EXIT

as_provisioner() { aws_as_user fernwood-provisioner "$@"; }

step() {  # step DESCRIPTION COMMAND... ; fails the level with the AWS error on denial
  local what="$1" out rc
  shift
  set +e
  out="$("$@" 2>&1)"
  rc=$?
  set -e
  if [ "$rc" -ne 0 ]; then
    echo "The provisioner cannot $what."
    echo "AWS said: $(printf '%s' "$out" | tail -1)"
    exit 1
  fi
}

step "create a user in fernwood-staff" as_provisioner cognito-idp admin-create-user --user-pool-id "$STAFF" \
  --username "$newbie" --message-action SUPPRESS --user-attributes "Name=email,Value=$newbie@example.com"
step "read a user back from fernwood-staff" as_provisioner cognito-idp admin-get-user --user-pool-id "$STAFF" \
  --username "$newbie"
step "set the first password of a new hire" as_provisioner cognito-idp admin-set-user-password \
  --user-pool-id "$STAFF" --username "$newbie" --password 'First-Day-2024!' --permanent
step "add the new hire to the employees group" as_provisioner cognito-idp admin-add-user-to-group \
  --user-pool-id "$STAFF" --username "$newbie" --group-name employees

# Least privilege.
if as_provisioner cognito-idp admin-delete-user --user-pool-id "$STAFF" --username "$newbie" >/dev/null 2>&1; then
  echo "The provisioner can now delete users. An onboarding job should never be able to remove people; grant only the actions it needs."
  exit 1
fi
if as_provisioner cognito-idp admin-create-user --user-pool-id "$CONTRACTORS" --username "intruder-$stamp" \
     --message-action SUPPRESS >/dev/null 2>&1; then
  echo "The provisioner can write to fernwood-contractors. It must only work on fernwood-staff."
  exit 1
fi

echo "The onboarding job can create, read, password-set and group new hires in fernwood-staff, and nothing else."

#!/usr/bin/env bash
# Shared plumbing for mission scripts. Source it from setup.sh / validate.sh /
# solution.sh:   source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"
#
# This file only wires up the emulator connection and a few credential
# utilities. Mission logic (what is broken, how it is checked) must live in the
# level's own scripts — never add scenario-specific helpers here.
#
# Must stay compatible with bash 3.2 (macOS /bin/bash).

: "${AWSMISSIONS_PORT:=4566}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
export AWS_REGION="${AWS_REGION:-$AWS_DEFAULT_REGION}"
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_ENDPOINT_URL="${AWS_ENDPOINT_URL:-http://localhost:${AWSMISSIONS_PORT}}"
export AWS_PAGER=""
ACCOUNT_ID="000000000000"
# Floci names the containers it spawns floci-aws-<namespace>-<service>-...
# (e.g. floci-aws-awsmissions-ecs-<task id>-<container>). See engine/floci.py.
if [ "$AWSMISSIONS_PORT" = 4566 ]; then _awsm_ns=awsmissions; else _awsm_ns="awsm$AWSMISSIONS_PORT"; fi
export AWSMISSIONS_NAMESPACE="${AWSMISSIONS_NAMESPACE:-$_awsm_ns}"

# aws_local ARGS...   — AWS CLI as the account root (bypasses IAM enforcement).
aws_local() {
  aws --endpoint-url="$AWS_ENDPOINT_URL" "$@"
}

# aws_with_creds AKID SECRET TOKEN ARGS...   — AWS CLI as an arbitrary principal.
# Pass "" as TOKEN for long-term keys. IAM policies ARE enforced for these calls.
aws_with_creds() {
  local akid="$1" secret="$2" token="$3"
  shift 3
  if [ -n "$token" ]; then
    AWS_ACCESS_KEY_ID="$akid" AWS_SECRET_ACCESS_KEY="$secret" AWS_SESSION_TOKEN="$token" \
      aws --endpoint-url="$AWS_ENDPOINT_URL" "$@"
  else
    env -u AWS_SESSION_TOKEN AWS_ACCESS_KEY_ID="$akid" AWS_SECRET_ACCESS_KEY="$secret" \
      aws --endpoint-url="$AWS_ENDPOINT_URL" "$@"
  fi
}

# aws_as_user USER ARGS...   — run one call as an IAM user with a throwaway key.
# The key is deleted afterwards so validators never exhaust the 2-key quota.
# Prints the CLI output; returns the CLI exit code.
aws_as_user() {
  local user="$1"
  shift
  local creds akid secret rc
  creds="$(aws_local iam create-access-key --user-name "$user" \
    --query 'AccessKey.[AccessKeyId,SecretAccessKey]' --output text)" || return 97
  akid="$(printf '%s' "$creds" | awk '{print $1}')"
  secret="$(printf '%s' "$creds" | awk '{print $2}')"
  rc=0
  aws_with_creds "$akid" "$secret" "" "$@" || rc=$?
  aws_local iam delete-access-key --user-name "$user" --access-key-id "$akid" >/dev/null 2>&1 || true
  return $rc
}

# aws_as_role ROLE_ARN CALLER_USER EXTERNAL_ID ARGS...
# CALLER_USER assumes ROLE_ARN (trust policy + caller's sts:AssumeRole permission
# are both evaluated), then runs one call with the session. Pass "" for
# EXTERNAL_ID when not needed. Returns 98 when AssumeRole itself is denied.
aws_as_role() {
  local role_arn="$1" caller="$2" external_id="$3"
  shift 3
  local creds akid secret ukey usecret extra="" rc=0 sess
  creds="$(aws_local iam create-access-key --user-name "$caller" \
    --query 'AccessKey.[AccessKeyId,SecretAccessKey]' --output text)" || return 97
  ukey="$(printf '%s' "$creds" | awk '{print $1}')"
  usecret="$(printf '%s' "$creds" | awk '{print $2}')"
  if [ -n "$external_id" ]; then extra="--external-id $external_id"; fi
  # shellcheck disable=SC2086
  sess="$(aws_with_creds "$ukey" "$usecret" "" sts assume-role --role-arn "$role_arn" \
    --role-session-name awsmissions-check $extra \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output text 2>/dev/null)" || rc=98
  aws_local iam delete-access-key --user-name "$caller" --access-key-id "$ukey" >/dev/null 2>&1 || true
  [ "$rc" -eq 0 ] || return $rc
  akid="$(printf '%s' "$sess" | awk '{print $1}')"
  secret="$(printf '%s' "$sess" | awk '{print $2}')"
  aws_with_creds "$akid" "$secret" "$(printf '%s' "$sess" | awk '{print $3}')" "$@"
}

# wait_for DESCRIPTION SECONDS COMMAND...   — poll until COMMAND succeeds.
wait_for() {
  local what="$1" seconds="$2" i=0
  shift 2
  while [ "$i" -lt "$seconds" ]; do
    if "$@" >/dev/null 2>&1; then return 0; fi
    sleep 1
    i=$((i + 1))
  done
  echo "Timed out waiting for: $what" >&2
  return 1
}

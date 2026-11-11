#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

nkeys() { aws_as_user "$1" iam list-access-keys --user-name "$2" --query 'length(AccessKeyMetadata)' --output text 2>/dev/null; }

if ! aws_local iam get-group --group-name redwood-contractors >/dev/null 2>&1; then
  echo "The group redwood-contractors is gone. Fix its policy; the group itself is fine."
  exit 1
fi

for who in redwood-kim redwood-lee; do
  # The calling session holds one throwaway key, so a user who sees their own keys gets at least 1.
  if ! c="$(nkeys "$who" "$who")" || [ -z "$c" ]; then
    echo "$who cannot list their own access keys."
    echo "Print the real ARN of the user (aws iam get-user --user-name $who) and compare it with the Resource in the policy."
    exit 1
  fi
  if ! aws_as_user "$who" iam get-user --user-name "$who" >/dev/null 2>&1; then
    echo "$who can list keys but cannot call GetUser on their own account."
    exit 1
  fi
done

# Only their own keys.
if nkeys redwood-kim redwood-lee >/dev/null 2>&1; then
  echo "redwood-kim can list redwood-lee's keys. The self-service policy must only match the caller's own user."
  exit 1
fi
if nkeys redwood-kim redwood-staff-ana >/dev/null 2>&1; then
  echo "A contractor can list keys of a staff member. Scope the Resource to the caller only."
  exit 1
fi

echo "Every contractor manages exactly their own credentials, nobody else's."

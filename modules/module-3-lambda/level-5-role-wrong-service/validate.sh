#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

role=lumen-thumb-scanner
res="$(mktemp)"; hdr="$(mktemp)"
trap 'rm -f "$res" "$hdr"' EXIT

if ! trust="$(aws_local iam get-role --role-name "$role" --query 'Role.AssumeRolePolicyDocument' --output json 2>/dev/null)"; then
  echo "The role $role is gone. Fix its trust policy in place; do not recreate it."
  exit 1
fi

# Everything an Allow statement names as a principal, flattened to one list.
principals="$(printf '%s' "$trust" | jq -r '[.Statement[] | select(.Effect=="Allow") | .Principal | (if type=="string" then [.] else ([.Service?, .AWS?] | flatten | map(select(. != null))) end)] | flatten | .[]')"

if printf '%s\n' "$principals" | grep -qx '\*'; then
  echo "The trust policy now trusts everyone (*). That would let any principal take over this role."
  exit 1
fi
if ! printf '%s\n' "$principals" | grep -qx 'lambda.amazonaws.com'; then
  echo "Lambda is still not a trusted principal of $role, so the service cannot assume it for the function."
  exit 1
fi
if printf '%s\n' "$principals" | grep -qx 'ec2.amazonaws.com'; then
  echo "ec2.amazonaws.com still appears in the trust policy. Nothing in EC2 should use this role any more, so drop it."
  exit 1
fi
if ! printf '%s\n' "$principals" | grep -qx 'arn:aws:iam::000000000000:user/ci-deployer'; then
  echo "The CI deployer lost its right to assume the role. Only the service principal should change."
  exit 1
fi
if ! printf '%s' "$trust" | jq -e '[.Statement[] | .Action] | flatten | all(. == "sts:AssumeRole")' >/dev/null; then
  echo "Every trust statement should use the action sts:AssumeRole."
  exit 1
fi

# The role's own permissions must have survived, and the function must work.
aws_local lambda invoke --function-name thumbnail-scanner "$res" >"$hdr" 2>&1 || { echo "Invoke failed: $(tail -1 "$hdr")"; exit 1; }
if jq -e '.FunctionError' "$hdr" >/dev/null 2>&1; then
  echo "thumbnail-scanner fails: $(jq -r '.errorMessage' "$res" | head -c 200)"
  echo "Did the role lose its permissions policy along the way?"
  exit 1
fi
if [ "$(jq -r '.count' "$res")" != "3" ]; then
  echo "The scanner ran but found $(jq -r '.count' "$res") pending uploads instead of 3."
  exit 1
fi

echo "lumen-thumb-scanner now trusts Lambda (and still the CI deployer), with its permissions intact."

#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

dest="$(mktemp)"
trap 'rm -f "$dest"' EXIT
echo "draft $(date +%s)" > "$dest"

# The shared policy must still exist and still be attached to the group.
if ! aws_local iam list-attached-group-policies --group-name lumen-staff \
     --query 'AttachedPolicies[].PolicyName' --output text | tr '\t' '\n' | grep -qx home-folders; then
  echo "home-folders is no longer attached to lumen-staff. Keep the shared policy; fix its content."
  exit 1
fi

fail=0
for pair in "lumen-alice lumen-bob" "lumen-bob lumen-alice"; do
  me="${pair% *}"
  other="${pair#* }"
  if ! out="$(aws_as_user "$me" s3api get-object --bucket lumen-homes --key "$me/notes.txt" "$dest" 2>&1)"; then
    echo "$me cannot read their own folder: $(printf '%s' "$out" | tail -1)"
    fail=1
    continue
  fi
  if ! aws_as_user "$me" s3api put-object --bucket lumen-homes --key "$me/draft.txt" --body "$dest" >/dev/null 2>&1; then
    echo "$me can read but not write to their own folder."
    fail=1
    continue
  fi
  if aws_as_user "$me" s3api get-object --bucket lumen-homes --key "$other/notes.txt" "$dest" >/dev/null 2>&1; then
    echo "$me can read $other's folder. The policy became too permissive."
    fail=1
  fi
done
if [ "$fail" -ne 0 ]; then
  echo "Group membership and the policy attachment are fine. Look closely at the policy document itself."
  exit 1
fi

echo "Everyone in lumen-staff gets their own folder in lumen-homes, and only their own."

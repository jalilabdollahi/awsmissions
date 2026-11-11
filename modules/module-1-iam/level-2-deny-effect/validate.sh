#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/pixelforge-uploader"
probe="$(mktemp)"
trap 'rm -f "$probe"' EXIT
echo "validation $(date +%s)" > "$probe"

if ! aws_local iam get-role --role-name pixelforge-uploader >/dev/null 2>&1; then
  echo "The role pixelforge-uploader no longer exists — the worker has nothing to assume."
  exit 1
fi

# Behaviour, not configuration: really upload as the role.
set +e
out="$(aws_as_role "$ROLE_ARN" upload-worker "" s3api put-object \
  --bucket pixelforge-uploads --key incoming/check.txt --body "$probe" 2>&1)"
rc=$?
set -e
if [ "$rc" -eq 98 ]; then
  echo "upload-worker can no longer assume pixelforge-uploader. Leave the trust policy alone — the problem is the permissions policy."
  exit 1
fi
if [ "$rc" -ne 0 ]; then
  if aws_local iam list-role-policies --role-name pixelforge-uploader --query 'PolicyNames' --output text | tr '\t' '\n' | while read -r name; do
       [ -n "$name" ] && aws_local iam get-role-policy --role-name pixelforge-uploader --policy-name "$name" --output json
     done | grep -q '"Deny"'; then
    echo "Uploads to incoming/ are still rejected. A Deny statement is still attached to the role — remember an explicit Deny beats every Allow."
  else
    echo "Uploads to incoming/ are still rejected: nothing on the role allows s3:PutObject on pixelforge-uploads/incoming/*."
  fi
  echo "S3 said: $(printf '%s' "$out" | tail -1)"
  exit 1
fi

# Least privilege: the fix must not open writes elsewhere.
if aws_as_role "$ROLE_ARN" upload-worker "" s3api put-object \
     --bucket pixelforge-billing-exports --key leak.txt --body "$probe" >/dev/null 2>&1; then
  echo "Uploads work — but the role can now also write to pixelforge-billing-exports. Scope the Allow to pixelforge-uploads/incoming/* only."
  exit 1
fi
if aws_as_role "$ROLE_ARN" upload-worker "" s3api put-object \
     --bucket pixelforge-uploads --key published/hijack.txt --body "$probe" >/dev/null 2>&1; then
  echo "Uploads work — but the role can now write outside incoming/ too. Keep the Resource limited to the incoming/ prefix."
  exit 1
fi

echo "pixelforge-uploader can upload to incoming/ again, and nowhere else. Support queue is draining."

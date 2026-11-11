#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=lumen-brand-assets
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

if ! aws_local s3api get-bucket-policy --bucket "$B" >/dev/null 2>&1; then
  echo "The bucket has no policy yet, so nothing is published."
  exit 1
fi

# Behaviour: a user with no permissions of its own plays the public.
if ! aws_as_user press-visitor s3api get-object --bucket "$B" --key public/logo.txt "$work/logo" >/dev/null 2>&1; then
  echo "A visitor still cannot download public/logo.txt."
  exit 1
fi
if aws_as_user press-visitor s3api get-object --bucket "$B" --key private/agency-contract-draft.txt "$work/draft" >/dev/null 2>&1; then
  echo "A visitor can download private/agency-contract-draft.txt. Only the press kit under public/ may be world-readable."
  exit 1
fi

# The fix must be a configured exception, not a removed protection.
cfg="$(aws_local s3api get-public-access-block --bucket "$B" --output json 2>/dev/null || true)"
if [ -z "$cfg" ]; then
  echo "The public access block configuration has been deleted entirely. Relax only what the public policy needs."
  exit 1
fi
if ! printf '%s' "$cfg" | python3 -c '
import json, sys
c = json.load(sys.stdin)["PublicAccessBlockConfiguration"]
sys.exit(0 if c.get("BlockPublicAcls") and c.get("IgnorePublicAcls") else 1)'
then
  echo "BlockPublicAcls and IgnorePublicAcls were switched off as well. Public ACLs must stay blocked."
  exit 1
fi
echo "public/ is downloadable by anyone, private/ is not, and public ACLs are still blocked."

#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

status="$(aws_local cloudformation describe-stacks --stack-name tidewater-manifests \
  --query 'Stacks[0].StackStatus' --output text 2>/dev/null || true)"
case "$status" in
  CREATE_COMPLETE|UPDATE_COMPLETE) ;;
  "") echo "The tidewater-manifests stack no longer exists."; exit 1 ;;
  *) echo "tidewater-manifests is in $status."; exit 1 ;;
esac

# Do what the dispatch app does: read the parameter, write to the bucket it names.
target="$(aws_local ssm get-parameter --name /tidewater/manifest-bucket \
  --query 'Parameter.Value' --output text 2>/dev/null || true)"
if [ -z "$target" ]; then
  echo "The parameter /tidewater/manifest-bucket does not exist."
  exit 1
fi

probe="$(mktemp)"
trap 'rm -f "$probe"' EXIT
echo "manifest 2024-06-01" > "$probe"
if ! aws_local s3api put-object --bucket "$target" --key daily/manifest.txt --body "$probe" >/dev/null 2>&1; then
  echo "The parameter points at '$target', and no bucket with that name exists. Where does that value come from in the template?"
  exit 1
fi

owned="$(aws_local cloudformation describe-stack-resources --stack-name tidewater-manifests \
  --query "StackResources[?ResourceType=='AWS::S3::Bucket'].PhysicalResourceId" --output text)"
if [ "$owned" != "$target" ]; then
  echo "The parameter names '$target', which is not the bucket owned by the stack ('$owned')."
  exit 1
fi

echo "/tidewater/manifest-bucket resolves to $target, and manifests can be written there."

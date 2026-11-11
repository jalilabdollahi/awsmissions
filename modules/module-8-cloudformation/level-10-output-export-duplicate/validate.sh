#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

stack_status() {
  aws_local cloudformation describe-stacks --stack-name "$1" \
    --query 'Stacks[0].StackStatus' --output text 2>/dev/null || true
}
export_value() {
  aws_local cloudformation list-exports \
    --query "Exports[?Name=='$1'].Value | [0]" --output text 2>/dev/null || true
}

for s in quayside-network quayside-web; do
  if [ "$(stack_status "$s")" != "CREATE_COMPLETE" ]; then
    echo "The existing stack $s is not healthy any more. The fix must not disturb it."
    exit 1
  fi
done
if [ "$(export_value quayside-assets-bucket)" != "quayside-shared-assets" ]; then
  echo "The export quayside-assets-bucket must still point at quayside-shared-assets; that name belongs to the network stack."
  exit 1
fi
if [ "$(aws_local ssm get-parameter --name /quayside/web/assets-bucket --query Parameter.Value --output text 2>/dev/null || true)" != "quayside-shared-assets" ]; then
  echo "The web stack's parameter no longer matches the network stack's bucket."
  exit 1
fi

status="$(stack_status quayside-reports)"
case "$status" in
  CREATE_COMPLETE|UPDATE_COMPLETE) ;;
  "") echo "quayside-reports does not exist yet. Deploy the reporting template under that name."; exit 1 ;;
  CREATE_FAILED|ROLLBACK_COMPLETE)
    reason="$(aws_local cloudformation describe-stack-events --stack-name quayside-reports \
      --query "StackEvents[?contains(ResourceStatus,'FAILED')].ResourceStatusReason | [0]" --output text)"
    echo "quayside-reports is in $status: $reason"
    echo "A failed stack has to be deleted before the name can be reused."
    exit 1 ;;
  *) echo "quayside-reports is in $status."; exit 1 ;;
esac

# The reporting stack must publish its OWN bucket under its OWN export name.
exports="$(aws_local cloudformation list-exports --query 'Exports[].[Name,Value]' --output text)"
found=""
while read -r name value; do
  [ -z "$name" ] && continue
  if [ "$value" = "quayside-report-data" ]; then found="$name"; fi
done <<EOF
$exports
EOF
if [ -z "$found" ]; then
  echo "quayside-reports is up but nothing exports its bucket (quayside-report-data). The team still needs the Output and Export."
  exit 1
fi
if [ "$found" = "quayside-assets-bucket" ]; then
  echo "The reporting bucket cannot own the name quayside-assets-bucket."
  exit 1
fi

echo "quayside-reports exports its bucket as '$found'; quayside-assets-bucket and the web stack are untouched."

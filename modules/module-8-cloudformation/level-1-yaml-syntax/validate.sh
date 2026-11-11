#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

STACK=harborlights-core
status="$(aws_local cloudformation describe-stacks --stack-name "$STACK" \
  --query 'Stacks[0].StackStatus' --output text 2>/dev/null || true)"

if [ -z "$status" ]; then
  echo "There is no stack called $STACK yet. Has create-stack been accepted? Run it and read the error."
  exit 1
fi
if [ "$status" != "CREATE_COMPLETE" ] && [ "$status" != "UPDATE_COMPLETE" ]; then
  echo "Stack $STACK is in $status, not CREATE_COMPLETE. Look at its events."
  exit 1
fi

versioning="$(aws_local s3api get-bucket-versioning --bucket harborlights-timetables \
  --query 'Status' --output text 2>/dev/null || true)"
if [ -z "$versioning" ] || [ "$versioning" = "None" ]; then
  if ! aws_local s3api head-bucket --bucket harborlights-timetables >/dev/null 2>&1; then
    echo "The stack exists, but the bucket harborlights-timetables does not. Every resource from the template should be there."
  else
    echo "Bucket harborlights-timetables exists but is not versioned; the template asked for versioning."
  fi
  exit 1
fi
if [ "$versioning" != "Enabled" ]; then
  echo "Bucket harborlights-timetables has versioning '$versioning'. Timetable edits must be recoverable (Enabled)."
  exit 1
fi

topics="$(aws_local sns list-topics --query 'Topics[].TopicArn' --output text)"
case "$topics" in
  *:harborlights-delay-alerts*) ;;
  *) echo "The delay-alert topic harborlights-delay-alerts is missing. Deploy the whole template, not a trimmed copy."; exit 1 ;;
esac

echo "harborlights-core is CREATE_COMPLETE: versioned timetable bucket and delay-alert topic are live."

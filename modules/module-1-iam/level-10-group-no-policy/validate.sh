#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp)"
probe_user="hd-probe-$$"
cleanup() {
  rm -f "$work"
  aws_local iam remove-user-from-group --group-name helpdesk-agents --user-name "$probe_user" >/dev/null 2>&1 || true
  aws_local iam delete-user --user-name "$probe_user" >/dev/null 2>&1 || true
}
trap cleanup EXIT
echo "attachment $(date +%s)" > "$work"

if ! aws_local iam get-group --group-name helpdesk-agents >/dev/null 2>&1; then
  echo "The group helpdesk-agents is gone. Keep it and give it permissions."
  exit 1
fi

# A brand-new agent joins the group: this proves the access comes from the group itself.
aws_local iam create-user --user-name "$probe_user" >/dev/null
aws_local iam add-user-to-group --group-name helpdesk-agents --user-name "$probe_user"

agent() { aws_as_user "$probe_user" "$@"; }

if ! out="$(agent s3api put-object --bucket ticket-attachments --key tickets/PP-2001/new.png --body "$work" 2>&1)"; then
  echo "A member of helpdesk-agents still cannot upload an attachment: $(printf '%s' "$out" | tail -1)"
  echo "Check what the group has attached: aws iam list-attached-group-policies --group-name helpdesk-agents"
  exit 1
fi
if ! agent s3api get-object --bucket ticket-attachments --key tickets/PP-1042/screen.png "$work" >/dev/null 2>&1; then
  echo "Uploading works but downloading an existing attachment is denied."
  exit 1
fi
if ! agent s3api list-objects-v2 --bucket ticket-attachments --prefix tickets/ >/dev/null 2>&1; then
  echo "Agents can fetch files but cannot list tickets/; they need to browse the bucket too."
  exit 1
fi
if agent s3api delete-object --bucket ticket-attachments --key tickets/PP-1042/screen.png >/dev/null 2>&1; then
  echo "Agents can delete customer attachments. Pick a policy that lets them upload and download only."
  exit 1
fi

# Existing members get the same access (it is not a one-off on the probe user).
if ! aws_as_user dana-helpdesk s3api put-object --bucket ticket-attachments --key tickets/PP-2002/dana.png --body "$work" >/dev/null 2>&1; then
  echo "Dana still cannot upload. Make sure the access is granted to the group, not only to someone else."
  exit 1
fi

echo "helpdesk-agents members can upload, download and list attachments, but not delete them."

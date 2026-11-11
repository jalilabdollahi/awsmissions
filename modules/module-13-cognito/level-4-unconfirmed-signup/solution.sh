#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='kestrel-members'].Id | [0]" --output text)"
CLIENT_ID="$(aws_local cognito-idp list-user-pool-clients --user-pool-id "$POOL_ID" \
  --query "UserPoolClients[?ClientName=='kestrel-ios'].ClientId | [0]" --output text)"

# The verification mail Kai never saw is in the emulator's outbox.
CODE="$(curl -s "$AWS_ENDPOINT_URL/_aws/ses" | jq -r \
  '[.messages[] | select(.Destination.ToAddresses[] == "kai@example.com")] | last | .Body.text_part' \
  | grep -o '[0-9]\{6\}')"

aws_local cognito-idp confirm-sign-up --client-id "$CLIENT_ID" --username kai \
  --confirmation-code "$CODE"

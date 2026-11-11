#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='stockroom-machines'].Id | [0]" --output text)"
SYNC_ID="$(aws_local cognito-idp list-user-pool-clients --user-pool-id "$POOL_ID" \
  --query "UserPoolClients[?ClientName=='nightly-sync'].ClientId | [0]" --output text)"

# 1. The scope has to exist on the resource server (update replaces the list, so keep the others).
aws_local cognito-idp update-resource-server --user-pool-id "$POOL_ID" --identifier inventory \
  --name "Inventory API" \
  --scopes ScopeName=read,ScopeDescription="Read stock levels" \
           ScopeName=write,ScopeDescription="Update stock levels" \
           ScopeName=admin,ScopeDescription="Change warehouse configuration" >/dev/null

# 2. The client has to be allowed to ask for it.
aws_local cognito-idp update-user-pool-client --user-pool-id "$POOL_ID" --client-id "$SYNC_ID" \
  --client-name nightly-sync --allowed-o-auth-flows client_credentials \
  --allowed-o-auth-scopes inventory/read inventory/write \
  --allowed-o-auth-flows-user-pool-client --supported-identity-providers COGNITO >/dev/null

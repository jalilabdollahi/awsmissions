#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

POOL_ID="$(aws_local cognito-idp create-user-pool --pool-name stockroom-machines \
  --query 'UserPool.Id' --output text)"

# The API was split off with only two scopes defined.
aws_local cognito-idp create-resource-server --user-pool-id "$POOL_ID" \
  --identifier inventory --name "Inventory API" \
  --scopes ScopeName=read,ScopeDescription="Read stock levels" \
           ScopeName=admin,ScopeDescription="Change warehouse configuration" >/dev/null

aws_local cognito-idp create-user-pool-client --user-pool-id "$POOL_ID" --client-name nightly-sync \
  --generate-secret --allowed-o-auth-flows client_credentials \
  --allowed-o-auth-scopes inventory/read \
  --allowed-o-auth-flows-user-pool-client --supported-identity-providers COGNITO >/dev/null

aws_local cognito-idp create-user-pool-client --user-pool-id "$POOL_ID" --client-name stockroom-dashboard \
  --generate-secret --allowed-o-auth-flows client_credentials \
  --allowed-o-auth-scopes inventory/read \
  --allowed-o-auth-flows-user-pool-client --supported-identity-providers COGNITO >/dev/null

echo "stockroom-machines is up. The nightly sync is being refused with invalid_scope."

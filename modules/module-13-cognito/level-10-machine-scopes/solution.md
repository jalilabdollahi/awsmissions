# Solution

The token endpoint gives two different `invalid_scope` answers, and both apply here:

- `Scope is invalid: inventory/write`: the **resource server** does not define a `write` scope at all.
- `Scope is not allowed for this client: inventory/write`: the scope exists, but the **client** is not allowed to request it.

1. Reproduce with the client's own secret and read the answer:

```bash
aws cognito-idp list-user-pools --max-results 10
aws cognito-idp list-user-pool-clients --user-pool-id <pool-id>
aws cognito-idp describe-user-pool-client --user-pool-id <pool-id> --client-id <client-id> --query UserPoolClient.[ClientSecret,AllowedOAuthScopes]
curl -s -X POST "$AWS_ENDPOINT_URL/cognito-idp/oauth2/token" -u "<client-id>:<secret>" \
  -d grant_type=client_credentials --data-urlencode "scope=inventory/read inventory/write"
aws cognito-idp describe-resource-server --user-pool-id <pool-id> --identifier inventory
```

2. Define the missing scope. The update **replaces** the list, so repeat `read` and `admin`:

```bash
aws cognito-idp update-resource-server --user-pool-id <pool-id> --identifier inventory --name "Inventory API" \
  --scopes ScopeName=read,ScopeDescription="Read stock levels" \
           ScopeName=write,ScopeDescription="Update stock levels" \
           ScopeName=admin,ScopeDescription="Change warehouse configuration"
```

3. Allow `nightly-sync` to request it. Again this call replaces settings, so pass the grant type and the rest:

```bash
aws cognito-idp update-user-pool-client --user-pool-id <pool-id> --client-id <client-id> --client-name nightly-sync \
  --allowed-o-auth-flows client_credentials --allowed-o-auth-scopes inventory/read inventory/write \
  --allowed-o-auth-flows-user-pool-client --supported-identity-providers COGNITO
```

4. Run `check`. It requests tokens as `nightly-sync` and as the dashboard, with the scopes from the briefing, and decodes the `scope` claim.

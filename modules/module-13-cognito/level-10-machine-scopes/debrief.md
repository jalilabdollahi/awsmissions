# Debrief: a scope has to be defined, and then granted

Machine-to-machine access in Cognito is built from three pieces:

1. A **resource server** (identifier such as `inventory`) that *defines* scopes: `inventory/read`, `inventory/write`, ...
2. An **app client** with `AllowedOAuthFlows = client_credentials` and a list of `AllowedOAuthScopes` it *may* request.
3. The **token endpoint**, where the client authenticates with its ID and secret and asks for scopes.

The token only contains what is in the intersection. Hence the two distinct errors: a scope nobody defined is `Scope is invalid`, and a scope that exists but was not granted to this client is `Scope is not allowed for this client`. Fixing one reveals the other, which is why this feels like whack-a-mole the first time.

**Where it went wrong at Stockroom:** the API was split off with the scopes that existed on day one (read, admin). The sync job's code was written against a design that had `write`, and nobody connected the two.

**Two replace-semantics traps in one fix**
- `update-resource-server` replaces the scope list. Passing only the new scope deletes `read` and `admin` and breaks every other consumer.
- `update-user-pool-client` replaces the client's settings. Pass the grant types and identity providers again, or the client stops being usable for OAuth.
- The client secret is not touched by either call.

**In real life**
- The API authorizing the token should check the `scope` claim (or use API Gateway's authorization scopes). A valid signature alone says nothing about permission.
- Give each machine its own client with the minimum scopes. When one leaks you rotate that one.
- Access tokens from the client-credentials grant have no user, no ID token and no refresh token. When one expires, request another.
- `admin`-style scopes deserve their own client that nobody uses day to day.

# Debrief: redirect URIs are matched exactly, and the flow must be switched on

Hosted-UI login is an OAuth 2.0 dance. The app sends the browser to `/oauth2/authorize` with a `client_id`, a `response_type`, scopes and a `redirect_uri`. After signing in, Cognito sends the browser back to that `redirect_uri` with a one-time `code`; the app exchanges the code at `/oauth2/token`. Two checks happen up front.

1. **`redirect_uri` must equal one of the client's registered callback URLs exactly.** Scheme, host, port, path and the trailing slash all count. `https://x/cb` and `https://x/cb/` are different. Cognito refuses wildcards in production, and only allows plain `http` for `localhost`. The strictness is the point: if any redirect target were accepted, an attacker could have the code delivered to their own site.
2. **The `response_type` must be enabled on the client.** `code` maps to the authorization-code flow (`AllowedOAuthFlows`), and the client must also have `AllowedOAuthFlowsUserPoolClient` switched on, otherwise OAuth is off entirely.

**Why not implicit?** The implicit flow puts tokens in the URL fragment, where browser history, referrer headers and scripts can reach them. The code flow keeps tokens off the redirect, and with PKCE it is the recommended choice for single-page apps and mobile apps alike. Cognito keeps implicit only for old integrations.

**In real life**
- Registered URLs are per client. Give production, staging and previews separate clients, or at least keep the list short and explicit.
- The domain (`create-user-pool-domain`) is what makes the hosted UI reachable on AWS. This lab emulates the same endpoints on its own URL.
- Treat a "redirect_mismatch" page as a configuration diff problem: copy the exact `redirect_uri` from the failing request into the client list, not the other way around.
- Logout URLs are matched the same strict way.
- This fix touched many settings at once, which is the usual way `update-user-pool-client` is used; remember it replaces what you leave out.

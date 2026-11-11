# Debrief: confidential clients and public clients

An app client is either **confidential** (it has a secret) or **public** (it does not). Cognito decides this when the client is created, and it never changes afterwards.

- With a secret, every `InitiateAuth`, `RespondToAuthChallenge`, `SignUp`, `ForgotPassword` and refresh call must include `SECRET_HASH = Base64(HMAC-SHA256(secret, username + clientId))`. Without it the call fails with `Client <id> has a secret; SECRET_HASH is required`.
- Without a secret, nothing extra is needed. Security then rests on the user's credentials and on the protocol (SRP, PKCE for OAuth).

**The rule of thumb:** a secret is only a secret if it lives where you control access. A server-side backend can keep one. A mobile app, a single-page app and a desktop client cannot: anyone can unpack the binary or read the JavaScript. Giving those a secret adds complexity and no protection.

**Why not just edit the client?** There is no API to remove a client secret. `update-user-pool-client` does not touch it, and a new secret means a new client. This is one reason to create **one client per application**: you can tune flows, token lifetimes and callback URLs for each, and retire one without breaking the others.

**In real life**
- One client per app also gives you clean per-app metrics and the ability to revoke a leaked client without an outage elsewhere.
- Compute `SECRET_HASH` with the exact username used for the call (for alias sign-in this is what the user typed). A mismatch gives `SECRET_HASH does not match`.
- For OAuth in public clients use the authorization code flow with PKCE, not the implicit flow.
- If a secret leaks, create a new client, migrate callers and delete the old client.

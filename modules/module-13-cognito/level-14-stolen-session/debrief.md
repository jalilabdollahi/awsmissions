# Debrief: sessions outlive passwords

A Cognito session is a bundle of three tokens, and each one has its own lifetime: the **access** and **ID** tokens are short (an hour by default) and are validated offline by whoever receives them, and the **refresh** token is long (30 days by default) and can mint new access tokens at will. Changing the password changes none of them. An attacker who holds a refresh token keeps access until it expires or is revoked.

**Tools, and what each one really does**

| Action | New sign-ins with the old password | Existing refresh tokens | Existing access tokens |
|---|---|---|---|
| `admin-set-user-password` / reset | blocked | still valid | still valid |
| `admin-disable-user` | blocked | refused while disabled | an API that validates offline keeps accepting them until expiry |
| `revoke-token` (one refresh token) | unaffected | that token dies | tokens minted from it die |
| `admin-user-global-sign-out` | unaffected | **all die** | **all die** |
| `admin-delete-user` | gone | gone | gone, but so is the account's identity |

The lesson of the table: incident response for an account is a *combination*. Global sign-out ends everything that exists; a reset or new password ends what could be created. Do one without the other and the attacker walks back in or never left.

**Why "global sign-out" beats "revoke the evidence"**
You only know the sessions you caught. Logs rotate, attackers open sessions from many places, and you cannot revoke a token you have never seen. `AdminUserGlobalSignOut` works on the *user*, not on a token.

**What not to do**
- **Delete and recreate the user.** The `sub` changes, and every database row, audit log or permission keyed by it now points at nothing.
- **Disable and forget.** The victim cannot work, and a disabled-forever account is how people end up with shared logins.
- **Reach for pool-wide measures** (deleting the client, rotating the pool) for one compromised user. Everyone else gets signed out for nothing.

**In real life**
- Access tokens already handed to an API stay valid until they expire, because the API validates them locally. Short access-token lifetimes (5 to 15 minutes) limit that window. Some stacks check revocation by calling `GetUser`, which is what this validator does.
- `EnableTokenRevocation` must be on for the client (it is by default) for revocation to work at all.
- Turn on advanced security features (compromised credentials detection, risk-based adaptive authentication) to catch dump passwords before they are used, and add MFA for the users who matter most.
- Rotate anything else that credential protected, and check CloudTrail for what the session did.

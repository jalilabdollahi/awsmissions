# Debrief: an app client only speaks the flows it lists

Every Cognito app client carries an `ExplicitAuthFlows` allow-list. A sign-in call names an auth flow, and Cognito checks that flow against the list before it even looks at the password. That is why nora's correct password made no difference: the error was about the client, not the user.

The flows you will meet most often:

| Flow | Used by | Notes |
|---|---|---|
| `ALLOW_USER_SRP_AUTH` | browsers and SDKs | The password never leaves the device; the recommended default |
| `ALLOW_USER_PASSWORD_AUTH` | simple apps, migration, scripts | Sends the password over TLS to Cognito; handy, a little less private |
| `ALLOW_REFRESH_TOKEN_AUTH` | every app that wants a session longer than the access token | Without it users are signed out when the access token expires |
| `ALLOW_ADMIN_USER_PASSWORD_AUTH` | trusted backends | Needs IAM credentials; never for a client shipped to end users |

**What went wrong at Brewline:** the v3 app was written against `USER_PASSWORD_AUTH`, but the client had been created for the web dashboard. The two teams never compared notes.

**Watch out for the replace semantics.** `update-user-pool-client` overwrites the whole configuration. If you pass only the one flow you want to add, the others disappear, and the next incident is "everybody got signed out". Always read the current value first, then write the full list.

**In real life**
- Treat a flow you do not need as attack surface and leave it off.
- A `NotAuthorizedException` means the credentials were rejected. An `InvalidParameterException` that says a flow is "not enabled" is almost always a client setting.
- Prefer SRP in mobile SDKs (Amplify does this for you) when you can, and keep `USER_PASSWORD_AUTH` for cases that need it, such as migrating users.

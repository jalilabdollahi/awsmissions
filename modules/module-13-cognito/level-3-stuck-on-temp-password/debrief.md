# Debrief: FORCE_CHANGE_PASSWORD is a state, not an error

`admin-create-user` makes an account in the status `FORCE_CHANGE_PASSWORD`. The user *can* authenticate with the temporary password, but Cognito will not hand out tokens until a permanent one is chosen. The sign-in call succeeds with a **challenge** (`ChallengeName: NEW_PASSWORD_REQUIRED` plus a `Session`) instead of an `AuthenticationResult`. A client that only looks for tokens sees nothing and shows a blank screen.

There are two ways out:

1. **The user answers the challenge:** `respond-to-auth-challenge --challenge-name NEW_PASSWORD_REQUIRED` with `NEW_PASSWORD` and the `Session` from the first call. This is what a proper app should implement (Amplify and the other SDKs do).
2. **An administrator sets it:** `admin-set-user-password --permanent` moves the account straight to `CONFIRMED`. Without `--permanent` the password is just another temporary one and the account stays stuck.

**Why it bit Lumen:** the portal was only ever tested with accounts that had already been through the first-login step.

**In real life**
- Temporary passwords expire (`TemporaryPasswordValidityDays`, default 7). An expired one needs `admin-create-user --message-action RESEND` to issue a new one.
- Challenges are a general mechanism: MFA codes, device verification and custom flows all arrive the same way. Teach the client to loop on `ChallengeName`.
- `admin-set-user-password --permanent` skips the user choosing their own secret. Use it for support or migration, and tell the user to change it.
- `list-users --filter 'cognito:user_status = "FORCE_CHANGE_PASSWORD"'` finds everyone who never finished onboarding.

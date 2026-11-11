# Debrief: sign-up is two steps, and confirmation is the second

`SignUp` only *registers* a user. The account is created `UNCONFIRMED`, and Cognito (with `AutoVerifiedAttributes` set to `email`) sends a code. The user, or your backend, completes the registration with `ConfirmSignUp`. Only then does the status become `CONFIRMED`, the email become `email_verified=true`, and sign-in start working. Trying to sign in earlier gives `UserNotConfirmedException`.

**Three ways to finish a pending sign-up**

| Way | Status | `email_verified` |
|---|---|---|
| `confirm-sign-up` with the emailed code | CONFIRMED | true |
| `admin-confirm-sign-up` | CONFIRMED | **unchanged** (false) |
| Pre sign-up Lambda returning `autoConfirmUser` / `autoVerifyEmail` | CONFIRMED | true only if `autoVerifyEmail` is set |

**Why the verified flag matters here:** password recovery (`forgot-password`) sends its code to a *verified* email or phone. For a user with an unverified address Cognito refuses with "no registered/verified email". Many teams discover this the first time a confirmed-by-admin user forgets a password.

**In real life**
- `resend-confirmation-code` sends a fresh code when the first one is lost or expired.
- Codes expire (24 hours for sign-up). Do not tell users to "try again later" without resending.
- SES sandbox limits or an unconfirmed sender address are the most common reasons a code truly never arrives in production.
- Store the SES or Cognito email-sending configuration in code, so a missing "from" address is caught in review.

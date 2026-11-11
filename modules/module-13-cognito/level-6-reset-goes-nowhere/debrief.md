# Debrief: recovery needs a verified destination

`ForgotPassword` delivers a code through the user's **verified** email or phone number. If neither exists you get `InvalidParameterException: Cannot reset password for the user as there is no registered/verified email or phone_number`. Cognito does this on purpose: a code sent to an address nobody has proven they control would let anyone who can edit a profile hijack the account.

Two fields matter together:

- `email`: where the mail goes.
- `email_verified`: whether Cognito trusts it for recovery. Setting an email through the admin API does **not** verify it unless you also set `email_verified=true`.

**Why this bit the library:** bulk imports create users with `AdminCreateUser`, which does not verify anything, and nobody noticed the typo because nobody had needed the address yet.

**In real life**
- When you import users, send `email_verified=true` only for addresses you have actually validated elsewhere. The CSV import format has an `email_verified` column for exactly this.
- A typo plus `email_verified=true` is the worst of both worlds: the code goes to a wrong inbox and Cognito believes it is fine. Fix the address first.
- Users can verify an address themselves with `update-user-attributes` followed by `verify-user-attribute`, using the code Cognito sends. Prefer that over admin overrides.
- Consider the pool's account recovery settings (`AccountRecoverySetting`) so recovery can fall back from email to phone.
- Audit regularly with `list-users --filter 'email_verified = "false"'`.

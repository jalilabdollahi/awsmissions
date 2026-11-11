# Debrief: the password policy is a pool-wide contract

The password policy lives on the **user pool**, not on the app client. Every path that sets a password checks it: `SignUp`, `ConfirmForgotPassword`, `ChangePassword`, `AdminSetUserPassword`, and the temporary password in `AdminCreateUser`. A violation always surfaces as `InvalidPasswordException`, with a message that says only that the password "does not conform to the configured password policy".

The levers are `MinimumLength` (6 to 99), the four `Require...` switches (upper, lower, numbers, symbols) and `TemporaryPasswordValidityDays` for admin-created users.

**What happened at Tidewater:** the security review set the strictest values it could think of. A 24-character password with a symbol is hard to type on a phone, so readers either gave up or reused the same awkward string everywhere.

**Length beats complexity.** Current guidance (NIST 800-63B) favours longer passwords and screening against breached lists over forced symbols. Raise `MinimumLength` before you add composition rules.

**In real life**
- A policy change only applies to **new** passwords. Existing users keep what they have until they change it.
- Do not "fix" a failing funnel by switching every requirement off. A policy that accepts `12345678` removes the point of a login.
- Pair the policy with advanced security features or an MFA setting if the data justifies it. Policy alone does not stop credential stuffing.
- `describe-user-pool` shows the policy, so put it in your infrastructure code and review changes like any other security setting.

# Debrief: LambdaConfig is replaced as a whole, and a trigger has to read the right data

**Fault one: the trigger list is not additive.** The pool's trigger configuration (`LambdaConfig`) is one object with a slot per trigger type. `update-user-pool --lambda-config` writes that whole object. Any slot you leave out is cleared. Attaching `PostConfirmation` alone silently detached `PreTokenGeneration`. Nothing failed: the pool was happy, the welcome mail worked, and the only visible effect was that a claim stopped appearing in tokens, two layers away from the change.

On AWS the same rule applies to nearly everything in `update-user-pool` (password policy, MFA settings, verification messages, auto-verified attributes, ...): omit it and it resets. The only safe routine is `describe-user-pool`, edit, send everything back, or manage the pool as code.

**Fault two: the function reads an attribute that does not exist.** Custom attributes are stored with the `custom:` prefix and the exact name given in the schema (`custom:tenant`). `attrs.get("custom:tenant_id")` quietly returns `None`, the code treats "no tenant" as normal, and the claim is skipped. A missing optional value hid a typo.

**How pre token generation works**
- Cognito invokes the trigger just before issuing tokens and sends the user's attributes in `request.userAttributes`.
- The function returns the event, with `response.claimsOverrideDetails` holding `claimsToAddOrOverride` (add or replace claims), `claimsToSuppress` (remove claims) and group overrides.
- The first generation of the trigger changes the ID token. Newer event versions (V2/V3) can also modify the access token, and are needed if your API validates access tokens.

**In real life**
- Make a missing tenant a hard failure (raise an exception) rather than a token without a claim. An API that treats "no tenant claim" as "no filter" is a data leak.
- Never let clients choose the claim. The values come from attributes only admins can change; custom attributes should not be writable from the app client unless you mean it.
- Only attach a trigger when the function exists and Cognito has permission to call it.
- Test the tokens, not the configuration. A decoded token is the real product of the trigger.

# Debrief: the Version element is not decoration

`"Version": "2012-10-17"` is the **policy language version**, not a date for your own bookkeeping. Two values exist:

- `2012-10-17`: current language; supports policy variables (`${aws:username}`, `${aws:PrincipalTag/team}`) and more.
- `2008-10-17`: legacy; variables are not substituted.

If you omit `Version`, the default is the legacy one. The policy is accepted, passes JSON validation, and simply never matches, because `lumen-homes/${aws:username}/*` is compared as literal text.

**Managed policy versions:** a customer-managed policy holds up to five versions, exactly one of which is the default. You change it by creating a new version with `--set-as-default`; older ones remain (`list-policy-versions`) so you can roll back, and you must delete one when you hit the limit of five.

**In real life**
- Always put `"Version": "2012-10-17"` first, in every policy, including trust policies and bucket policies.
- One policy with `${aws:username}` replaces N per-user policies. For roles or federated users, use `${aws:PrincipalTag/...}` or `${aws:userid}` since there is no IAM username.
- Remember that creating a new managed policy version affects every group, user and role it is attached to immediately.

# Solution

Stopping an account takeover takes two independent actions. Changing the password stops *new* logins but does nothing to sessions that already exist, and revoking the tokens you can see does nothing for the ones you cannot.

1. Look at the evidence:

```bash
aws s3 ls s3://halyard-ir-evidence/ --recursive
aws s3 cp s3://halyard-ir-evidence/captured/laptop.json -
aws cognito-idp list-user-pools --max-results 10
```

2. End **every** session of the account. `admin-user-global-sign-out` revokes all refresh tokens of the user, and with them the access tokens derived from them, including sessions you never captured:

```bash
aws cognito-idp admin-user-global-sign-out --user-pool-id <pool-id> --username mara
```

(Per-token alternative: `revoke-token --client-id <id> --token <refresh token>` for each refresh token you know. It cannot reach the ones you do not.)

3. Invalidate the leaked password without choosing one on Mara's behalf. `admin-reset-user-password` puts the account in `RESET_REQUIRED`; Mara completes the forgot-password flow when she wakes up. (Setting a new permanent password with `admin-set-user-password --permanent` and handing it to her over a safe channel also satisfies the check.)

```bash
aws cognito-idp admin-reset-user-password --user-pool-id <pool-id> --username mara
```

4. Run `check`. The validator replays every captured token against `GetUser` and the refresh flow, tries the leaked password, and confirms Noah's session still works.

Do not delete Mara's user (it changes her `sub`, the identity every other system uses), and do not disable the account for good: that locks out the victim.

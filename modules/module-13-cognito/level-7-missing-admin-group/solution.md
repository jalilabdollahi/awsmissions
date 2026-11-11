# Solution

The console looks for the exact group name `ops-admins`. Dara belongs to a group called `ops-admin`, one letter short. Group names are plain strings, so Cognito sees two unrelated groups.

1. Compare the claim with the groups that exist:

```bash
aws cognito-idp list-user-pools --max-results 10
aws cognito-idp list-groups --user-pool-id <pool-id>
aws cognito-idp admin-list-groups-for-user --user-pool-id <pool-id> --username dara
```

2. Create the group the console expects and put Dara in it:

```bash
aws cognito-idp create-group --user-pool-id <pool-id> --group-name ops-admins --precedence 1
aws cognito-idp admin-add-user-to-group --user-pool-id <pool-id> --username dara --group-name ops-admins
```

3. Dara must sign in again, because a token is a snapshot taken at sign-in. Run `check`; the validator signs in as both users and decodes their ID tokens.

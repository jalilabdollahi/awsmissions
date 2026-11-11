# Debrief: `cognito:groups` is just a list of names, copied into the token at sign-in

When a user belongs to user-pool groups, Cognito adds a `cognito:groups` claim to **both** the ID token and the access token. Applications and API authorizers typically compare names in that list to decide what a person may do. Two details decide whether it works:

1. **The comparison is an exact string match.** `ops-admin` and `ops-admins` are different groups. Nothing validates names against what your application expects.
2. **The claim is a snapshot.** It is written when a token is issued. Changing a user's groups does not alter tokens already handed out; the user gets the new claim in tokens issued after the change, so ask them to sign in again.

**What happened at Parcelpost:** somebody created the group by hand a year ago with a typo, then the console was written against the documented name. It "worked" in the staging pool, where the group was created from a script.

**In real life**
- Treat group names as an API. Create them in infrastructure code, share a constant between the pool setup and the application, and fail closed (deny) when the claim is missing.
- Groups can also carry an IAM role (`--role-arn`). With identity pools, the role in `cognito:preferred_role` is how group membership turns into AWS permissions; precedence breaks ties between groups.
- A user with no groups gets no `cognito:groups` claim at all, not an empty list, so code must handle a missing key.
- Removing a user from a group does not revoke a token that is still valid. For urgent revocation also sign the user out globally (see the incident-response level).
- Do not "fix" this by adding every user to the admin group. That is the quickest way to an incident.

# Debrief: UpdateUserPoolClient replaces everything you leave out

This is one of the most common Cognito outages, and it comes from a design choice in the API: the update calls (`UpdateUserPoolClient`, and `UpdateUserPool`) are not patches. Parameters you omit revert to their defaults. The AWS documentation says it plainly, but the CLI makes it easy to forget: you type one flag, the command succeeds, and a dozen other settings quietly disappear.

What disappeared here, and the visible symptom of each:

| Omitted | Reverts to | Symptom |
|---|---|---|
| `--explicit-auth-flows` | an empty list | `... flow not enabled for this client` on sign-in |
| token validities and units | 60 min / 60 min / 30 days | tokens that live twice as long as agreed (no error at all) |
| callback / logout URLs | none | hosted-UI login fails with a redirect mismatch |
| OAuth flows and scopes | none | the authorize endpoint refuses the client |

Notice that the first symptom is loud and the second is silent. A token lifetime that is twice what security asked for will not page anyone.

**The safe workflow**
1. `describe-user-pool-client` and save the output.
2. Edit the saved document (the describe output is nearly the update input).
3. Send the full thing back. Better: keep the client in Terraform, CloudFormation or CDK, where the full definition is always applied.

**In real life**
- Do not remove or recreate a client to "reset" it. The client ID is baked into the apps and a new client has a new ID and a new secret.
- Token lifetime has units. A bare `--access-token-validity 30` is interpreted in whatever `TokenValidityUnits` says (hours by default), so always pass the units explicitly.
- Callback URLs must match exactly (scheme, host, port, path, and trailing slash). Keep a short list, and never add wildcards for production.

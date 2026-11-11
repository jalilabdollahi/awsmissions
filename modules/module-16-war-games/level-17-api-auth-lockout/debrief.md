# Debrief: PX-318, the auth maze

## Root causes
| Gate | Fault | What it looked like |
|---|---|---|
| 1 Method | `AWS_IAM` instead of `CUSTOM` | Partners using tokens got `403 Missing Authentication Token` |
| 2 Authorizer | identity source `X-Admin-Token` | With the right method type, calls were `401 Unauthorized`: the token was never found |
| 3 Authorizer role | no `ssm:GetParameter` | Authorizer errors (fail closed) look like auth failures |
| 4 Backend role | `GetItem` instead of `Scan` | Partner B's signed calls got past auth and then `502` |

## Timeline
- Migration: script recreates the API from the old definition, with IAM auth defaulted on for safety; authorizer copied from the admin API; roles recreated "minimal".
- First partner call: 403. Partner B changes its client to SigV4 and sees a different failure (the 502) which hides the earlier ones.
- The internal smoke test with the token and the Authorization header hits gate 2 and returns 401.

## Why the errors differ
Each gate answers differently. API Gateway first decides *how* to authenticate (method authorization type), then *where to find* the credential (identity source), then runs the authorizer (a Lambda with its own role), and only then invokes the integration (another Lambda with another role). The status code tells you the furthest gate the request reached.

## Lessons
- Test each Lambda in the chain directly with a realistic event; permission errors are much easier to read there than as a generic `500/502` from API Gateway.
- Never "fix" an auth problem by switching auth off. The validator treats an unauthenticated method as a blocker because that is what an attacker hopes for.
- Remember stage deployments: API edits are drafts until deployed.
- Authorizer result caching (TTL) can keep a bad decision alive for minutes after a fix. Know your TTL when testing.

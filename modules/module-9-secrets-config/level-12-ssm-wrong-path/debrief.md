# Debrief: paths are prefixes, not folders, and permissions follow them

Parameter names with slashes form a **hierarchy by convention**. `/lattice/prod/db-host` and `/lattice/production/db-host` are two unrelated parameters in two unrelated subtrees; `get-parameters-by-path` is a plain prefix match on the name, and a `get-parameter` for a name that does not exist is simply `ParameterNotFound`.

**Why the path is also a security boundary.** IAM policies match parameter ARNs, `arn:aws:ssm:<region>:<account>:parameter/lattice/production/*`. Granting one subtree and not another is how you give each service only its own configuration. That is why "just widen the policy" is the wrong reflex: you would hand the service another environment's data.

**Naming conventions that prevent this class of bug**
- Decide the hierarchy once: `/<org>/<env>/<service>/<setting>`. Write it down and enforce it in the provisioning module, not in a shell script copied per team.
- Use the *same* environment word everywhere (`prod`, not `prod` here and `production` there) and make it a variable in your IaC.
- Hand the service its base path through an environment variable so a change is a deploy rather than a code change.

**Moving parameters.** There is no rename. Copy then delete, or keep both for a migration period. A `SecureString` must be re-written with the right type (and key); read the source with `--with-decryption` so you copy the real value.

**Efficiency.** One `get-parameters-by-path --recursive` call is cheaper than many single reads and keeps a service's config consistent, but note it pages at 10 results per call; the CLI pages automatically, SDK clients need a loop.

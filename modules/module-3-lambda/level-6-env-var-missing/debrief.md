# Debrief: environment variables are replaced, not merged

Lambda environment variables are plain key/value settings injected into the process when the execution environment starts. They are how one artifact runs in many stages.

Three lessons from this mission:

1. **Missing variable = crash at the first access.** `os.environ["X"]` raises `KeyError` (Python) and `process.env.X` is silently `undefined` (Node.js), which is worse. Read required settings once at import time with a clear error, or use `.get()` with a safe default only when a default is truly safe.
2. **`update-function-configuration --environment` replaces the entire map.** Sending only `RATES_TABLE` would have deleted `FX_PRECISION`, and the function would then happily return answers with two decimals. The checker compares the exact digits to catch this silent regression. Always read the current map first (`get-function-configuration --query Environment`) and send the merged result.
3. **A correct variable can still point at a forbidden resource.** Pointing `RATES_TABLE` at the staging table would give a wrong-looking error: not a `KeyError` but an `AccessDeniedException` from DynamoDB, because the role grants `GetItem` on the production table only. The execution role is the real boundary, not the variable.

**In real life**
- Do not put secrets in environment variables in plain text; reference Secrets Manager or SSM Parameter Store and fetch at cold start (cached), or use encrypted env vars with a customer-managed KMS key.
- Total environment size is limited to 4 KB.
- Infrastructure-as-code tools set the full map on every deploy, so a manual edit gets overwritten on the next release. Fix the template as well.

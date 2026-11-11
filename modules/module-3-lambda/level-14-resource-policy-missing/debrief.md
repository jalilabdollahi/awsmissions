# Debrief: who may call a function is written on the function

Lambda has two permission directions that people often mix up:

| Policy | Controls | Set with |
|---|---|---|
| **Execution role** (identity policy) | what the function may do to other services | IAM role |
| **Resource-based policy** | who may invoke the function | `add-permission` / `remove-permission` |

Here the question is the second: *who may invoke?* In the same account, an invocation is allowed if **either** the caller's own identity policy **or** the function's resource policy allows it (and nothing denies it). That is why the contract works: the resource policy lets Cartwheel grant access without ever touching the partner's IAM user. Across accounts you need *both* sides.

`add-permission` adds one statement. The pieces:
- `--principal`: a service (`s3.amazonaws.com`, `events.amazonaws.com`), an account, a user or role ARN, or `*`.
- `--action`: usually `lambda:InvokeFunction`.
- `--source-arn` / `--source-account`: condition keys to say *which* bucket, rule or topic may call (use them for services).
- `--statement-id`: unique name so you can later `remove-permission` it.

`--principal '*'` with no condition makes the function publicly invocable, a common misconfiguration. The checker therefore tries FastLane, whose contract ended, and also tests that ShipRight cannot read the function's configuration, which would show an over-broad action such as `lambda:*`.

**In real life**
- Review resource policies with `aws lambda get-policy`; IAM Access Analyzer flags public and cross-account ones automatically.
- Name statement IDs after the partner and contract (`allow-shipright-invoke`), so a clean-up has an audit trail.
- Prefer roles over users for partner access (they have no long-lived keys), and prefer an API layer (API Gateway with usage plans) when partners are not in your AWS organisation.

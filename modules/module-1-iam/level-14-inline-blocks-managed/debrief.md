# Debrief: Allows add up, but a single Deny wins

A request is evaluated against **all** the policies that apply to the caller: managed and inline, user and group, plus boundaries and SCPs. The decision logic:

1. If any applicable policy has an explicit **Deny** matching the request, it is denied. Full stop.
2. Otherwise, if some policy **Allows** it (and no boundary or SCP cuts it off), it is allowed.
3. Otherwise it is an implicit deny.

`AmazonS3FullAccess` supplied an Allow, so people stared at it for an hour. The deny was somewhere they did not look: in a small inline policy named after a freeze from two years ago.

**Why the fix is surgical:** the user's other Deny (`LedgerIsReadOnly`) is a good one. It is scoped to a single bucket and carries a meaningful `Sid`. Cleaning up by deleting everything would trade an outage for a security regression.

**In real life**
- Use `aws iam simulate-principal-policy` with `--action-names` and `--resource-arns`; the result's `MatchedStatements` shows which policy produced the decision.
- Give every Deny a clear `Sid` and, when it is temporary, a `Condition` with `aws:CurrentTime` or an expiry tag so it does not outlive the reason for it.
- Prefer group- or role-level guardrails (and SCPs in AWS Organizations) over per-user inline denies; they are easier to audit.
- IAM Access Analyzer and the "Last accessed" data help you find policies nobody uses any more.

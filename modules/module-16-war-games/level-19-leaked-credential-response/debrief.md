# Debrief: SEC-INC-0402, build credentials in a public repo

## What went wrong
1. A long-lived access key for a powerful user was committed to a public repository and stayed valid for 19 days.
2. The user carried `iam:*` and `s3:*` on everything, so one leaked key could create new identities.
3. The attacker planted two persistence mechanisms: a hidden admin user with its own key, and a role trusting a foreign account. Rotating the leaked key alone would have left both open.
4. CI read its credential from a parameter, so a careless "disable the key right now" would also have stopped the release.

## Response order (and why)
- **Recover before you cut**: create the replacement and update the consumer, then kill the old key. For a real outage-sensitive pipeline you rotate first; the exposure window during that minute is far smaller than the 19 days already lost.
- **Contain**: delete or deactivate the exposed key. Deactivation is reversible and good for forensics; deletion is final. Keep the evidence of the key id.
- **Eradicate**: hunt for what the attacker created with the leaked rights. IAM will not delete a user with keys or attached policies, nor a role with attached policies; you have to peel those away first.
- **Harden**: the real root cause is a long-lived credential with far too much power.

## Timeline
- T-19d: key committed. T-6d: first use from an unfamiliar network; persistence planted within minutes. T0: scanner alert. T+40m: containment complete.

## Lessons
- Prefer short-lived credentials (OIDC federation from CI to an IAM role) over IAM user keys; there is then nothing to leak.
- Scan commits for secrets before they leave the developer machine, and enable the provider's own detection and auto-quarantine of leaked keys.
- Alert on `CreateUser`, `CreateAccessKey`, `AttachUserPolicy` and trust-policy changes naming external accounts; use IAM Access Analyzer for external-access findings.
- Review "what could this identity create?" and not only "what can it read?".

# Debrief: credentials belong to the platform, not to the code

**Why embedded keys are bad.** An access key in an environment variable is long-lived, readable by anyone with `lambda:GetFunctionConfiguration`, copied into logs, backups, console screenshots and infrastructure state files, and it carries the permissions of whichever user it belongs to, which here were broader than the function needs. It also overrides the temporary credentials Lambda injects.

**What Lambda gives you instead.** Every function has an execution role. At invocation Lambda calls STS and exposes short-lived credentials to the SDK through environment variables and the default credential chain; code just creates a client with no keys. They expire within hours and are scoped by the role's policy.

**The three steps are all required**
1. *Replace* the credential with a role (least privilege: one action, one secret ARN).
2. *Remove* the secret from configuration. Remember that `update-function-configuration --environment` overwrites all variables: omit one and you break the function.
3. *Revoke* the exposed key. Removing it from the configuration does not stop someone who copied it. Deactivate first (reversible, to see what breaks), delete afterwards, and check CloudTrail for use of the key by unexpected callers (`aws iam get-access-key-last-used`).

**Related practices**
- Keep non-secret configuration in environment variables, and store only the secret's *name* there (as here); the code fetches the value at runtime using its role.
- Use secret scanning in CI (git hooks, GitHub secret scanning) and AWS IAM Access Analyzer to find unused access keys.
- Prefer roles everywhere: ECS task roles, EC2 instance profiles, IAM roles for service accounts on EKS, and `sts:AssumeRole` for CI.
- A trust policy and a permissions policy are separate: the first says who can *be* the role (the Lambda service), the second says what it can do.

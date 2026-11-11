# Debrief: SSM permissions have three moving parts

Reading a parameter looks like one API call; authorising it takes up to three independent checks.

**1. The action.** `ssm:GetParameter`, `ssm:GetParameters`, `ssm:GetParametersByPath` and `ssm:GetParameterHistory` are separate actions. Grant what the code really calls; SDK helpers often use the batch or path variants behind your back, so check the CloudTrail event names when in doubt.

**2. The parameter ARN.** Format: `arn:aws:ssm:<region>:<account-id>:parameter<name>`, where `<name>` keeps its leading slash. So `/kiln/prod/queue-url` is `...:parameter/kiln/prod/queue-url`. The doubled-slash form `parameter//kiln/...` is a very common mistake: it is syntactically valid, matches nothing, and fails closed. For a parameter *without* a leading slash (`my-param`), the ARN is `...:parameter/my-param`.

**3. The key, for SecureStrings.** The caller must be allowed to `kms:Decrypt` with the key that protects the value (for the default AWS-managed `alias/aws/ssm` key the key policy already allows use via SSM; for a customer-managed key your IAM policy and key policy must both permit it). In IAM policies the key is identified by its **key ARN**, never by alias; use `kms:ResourceAliases` as a condition if you want alias-based rules.

**Scoping tips**
- `parameter/kiln/prod/*` matches everything under that prefix *including deeper levels*, but not `parameter/kiln-admin/...`; the trailing slash in the prefix is what keeps neighbours out.
- Combine `kms:Decrypt` with the condition `kms:ViaService: ssm.us-east-1.amazonaws.com` so the role can decrypt only through Parameter Store, not use the key directly.

**Debugging order for AccessDenied:** action name, then resource ARN, then KMS, then explicit denies (SCP, permission boundary, resource policy). `aws iam simulate-principal-policy` answers the first three in one call.

**About this emulator.** It checks IAM for single-parameter reads (`GetParameter`) and for KMS actions you simulate, but does not enforce key permissions inside SSM itself, which is why the KMS part of this mission is verified with the IAM simulator.

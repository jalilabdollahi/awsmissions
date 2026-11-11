# Solution

The group exists and has members, but has no policies. The security team already wrote three managed policies for the bucket; pick the one that matches the requirement (upload + download, no delete) and attach it to the **group**.

1. Compare the candidates:

```bash
aws iam list-policies --scope Local --query 'Policies[].[PolicyName,Arn,DefaultVersionId]' --output text
aws iam get-policy-version --policy-arn arn:aws:iam::000000000000:policy/attachments-agent --version-id v1
```

   - `attachments-viewer`: list and get only (cannot upload).
   - `attachments-agent`: list, get and put. This is the one.
   - `attachments-owner`: `s3:*` (can delete and change bucket settings).

2. Attach it to the group:

```bash
aws iam attach-group-policy --group-name helpdesk-agents --policy-arn arn:aws:iam::000000000000:policy/attachments-agent
```

`check` creates a throw-away agent, adds it to the group and tests upload, download, list and delete.

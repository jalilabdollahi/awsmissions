# Solution

The JSON is syntactically fine, but each of the three statements has its own semantic fault:

| Statement | Fault | Fix |
|---|---|---|
| `PartnerListsDropFolders` | `StringEquals` compares `s3:prefix` literally, so the value `outbound/*` only matches a prefix that is literally `outbound/*` | use `StringLike` so `*` is a wildcard |
| `PartnerDownloadsOutbound` | `s3:GetObjects` is not an S3 action (the action is `s3:GetObject`) | fix the action name |
| `PartnerUploadsInbound` | the Principal is in account `123456789012`, but the user lives in `000000000000` | use the real user ARN |

1. Inspect:

```bash
aws s3api get-bucket-policy --bucket quillhouse-partner-drop --query Policy --output text
aws iam get-user --user-name partner-sync --query User.Arn
```

2. Edit `bucket-policy.json` accordingly, then apply:

```bash
aws s3api put-bucket-policy --bucket quillhouse-partner-drop --policy file://bucket-policy.json
```

The validator acts as `partner-sync` for every allowed operation and every forbidden one (including a prefix-less listing, which the `s3:prefix` condition must still refuse).

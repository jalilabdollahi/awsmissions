# Solution

`report-access` only contains `s3:ListBucket`. Listing a bucket and reading an object are two different permissions on two different kinds of ARN, so the user can see file names but cannot open the files.

1. Add a second statement to `policy.json` (`edit`):

```json
{
  "Sid": "ReadReportObjects",
  "Effect": "Allow",
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::harborline-reports/reports/*"
}
```

2. Replace the inline policy with the edited file:

```bash
aws iam put-user-policy \
  --user-name ledgerlens-report \
  --policy-name report-access \
  --policy-document file://policy.json
```

3. Run `check`. It downloads the Q3 report as the user and makes sure payroll, writes and deletes are still blocked.

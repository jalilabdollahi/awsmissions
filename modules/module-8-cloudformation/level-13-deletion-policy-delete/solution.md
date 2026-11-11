# Solution

The template declares no `DeletionPolicy`, so every resource defaults to `Delete`. Deleting the stack would drop the table with all its records, and the delete would stall on the non-empty bucket.

1. Add the policy to the two stateful resources in `template.yaml` (`edit`):

```yaml
  LedgerArchive:
    Type: AWS::S3::Bucket
    DeletionPolicy: Retain
    ...
  LedgerIndex:
    Type: AWS::DynamoDB::Table
    DeletionPolicy: Retain
    ...
```

2. Apply it to the live stack first. The policy is read from the deployed template, not from your file:

```bash
aws cloudformation update-stack --stack-name nightjar-archive --template-body file://template.yaml
aws cloudformation wait stack-update-complete --stack-name nightjar-archive
```

3. Now retire the stack:

```bash
aws cloudformation delete-stack --stack-name nightjar-archive
aws cloudformation wait stack-delete-complete --stack-name nightjar-archive
```

The events topic is deleted; the bucket and table stay, no longer managed by any stack.

4. `check` confirms the stack is gone, the topic is gone, and the table (3 records) and the bucket (2 exports) are intact.

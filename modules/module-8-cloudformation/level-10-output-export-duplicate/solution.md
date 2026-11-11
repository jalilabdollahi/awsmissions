# Solution

The copied template exports its bucket as `quayside-assets-bucket`, a name already owned by `quayside-network`. CloudFormation refuses duplicate export names, so `quayside-reports` ends in `CREATE_FAILED` with `Export with name quayside-assets-bucket is already exported by another stack`.

1. Find out who owns the name:

```bash
aws cloudformation list-exports
aws cloudformation describe-stack-events --stack-name quayside-reports
```

2. In `template.yaml` (`edit`) rename the export, for example:

```yaml
Export:
  Name: quayside-reports-bucket
```

3. Delete the failed stack, then deploy the corrected template:

```bash
aws cloudformation delete-stack --stack-name quayside-reports
aws cloudformation wait stack-delete-complete --stack-name quayside-reports
aws cloudformation create-stack --stack-name quayside-reports --template-body file://template.yaml
aws cloudformation wait stack-create-complete --stack-name quayside-reports
```

4. `check` confirms the network export and the web stack are unchanged and that the reporting bucket is exported under a different name.

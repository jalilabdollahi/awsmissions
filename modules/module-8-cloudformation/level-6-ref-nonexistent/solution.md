# Solution

The parameter's value is built from `!Ref ManifestBuket`, but the bucket's logical ID is `ManifestBucket`. No resource has the misspelled name, so the parameter ended up holding the literal text `ManifestBuket`, and writes to that "bucket" fail with `NoSuchBucket`.

1. See the wrong value:

```bash
aws ssm get-parameter --name /tidewater/manifest-bucket --query Parameter.Value
```

2. Fix the reference in `template.yaml` (`edit`): `Value: !Ref ManifestBucket`.

3. Update the stack:

```bash
aws cloudformation update-stack --stack-name tidewater-manifests --template-body file://template.yaml
aws cloudformation wait stack-update-complete --stack-name tidewater-manifests
```

4. `check` reads the parameter, writes a manifest to the bucket it names, and confirms that bucket is the one the stack owns.

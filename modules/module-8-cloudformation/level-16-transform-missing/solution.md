# Solution

```bash
# Edit the local template or policy artifact first
$EDITOR template.yaml
# This edited file applies to: Transform: AWS::Serverless-2016-10-31

# Then apply the fix
aws cloudformation package --template-file template.yaml --s3-bucket mission-bucket --output-template-file packaged.yaml
```

# Solution

```bash
aws lambda add-permission   --function-name mission-function   --statement-id allow-s3   --action lambda:InvokeFunction   --principal s3.amazonaws.com   --source-arn arn:aws:s3:::uploads-bucket
```

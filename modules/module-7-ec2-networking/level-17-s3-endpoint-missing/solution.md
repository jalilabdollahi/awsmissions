# Solution

A **gateway endpoint** adds a route to S3 inside the route tables you select, so the private subnet reaches S3 over the AWS network with no NAT. Its policy is the guardrail: the default policy allows every bucket, so replace it with one that names only `quartz-exports`.

```bash
cat > endpoint-policy.json <<'JSON'
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*",
 "Action":["s3:GetObject","s3:PutObject","s3:ListBucket"],
 "Resource":["arn:aws:s3:::quartz-exports","arn:aws:s3:::quartz-exports/*"]}]}
JSON
aws ec2 create-vpc-endpoint --vpc-id <quartz-vpc> --vpc-endpoint-type Gateway \
  --service-name com.amazonaws.us-east-1.s3 --route-table-ids <quartz-private rtb> \
  --policy-document file://endpoint-policy.json
```

# Solution

Two separate problems. An EC2 instance cannot use a role directly; it needs an **instance profile**. And the role's trust policy names `lambda.amazonaws.com`, so EC2 is not allowed to assume it.

```bash
aws iam update-assume-role-policy --role-name ember-app-role --policy-document '{
  "Version":"2012-10-17",
  "Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}'

aws iam create-instance-profile --instance-profile-name ember-app-profile
aws iam add-role-to-instance-profile --instance-profile-name ember-app-profile --role-name ember-app-role

IID=$(aws ec2 describe-instances --filters Name=tag:Name,Values=ember-api --query 'Reservations[0].Instances[0].InstanceId' --output text)
aws ec2 associate-iam-instance-profile --instance-id $IID --iam-instance-profile Name=ember-app-profile
```

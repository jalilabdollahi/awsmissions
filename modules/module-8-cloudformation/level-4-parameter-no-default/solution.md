# Solution

`BranchCode` has no `Default`, and the deploy script does not pass it, so `create-stack` fails with `Parameters: [BranchCode] must have values` before anything is created.

Because this template is meant for every branch, the best fix is to supply the value at deploy time instead of hard-coding one:

```bash
aws cloudformation create-stack --stack-name fernwood-orders \
  --template-body file://template.yaml \
  --parameters ParameterKey=BranchCode,ParameterValue=dub
aws cloudformation wait stack-create-complete --stack-name fernwood-orders
```

(Adding `Default: dub` to the parameter would also work, but then every branch silently deploys to Dublin's bucket if someone forgets the flag.)

`check` reads the stack's `OrdersBucket` output and confirms the bucket exists and is named `fernwood-orders-dub`.

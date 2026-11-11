# Solution

Two independent faults produce the same symptom, an ID token without `tenant`:

1. **The trigger is no longer attached.** `update-user-pool --lambda-config` takes the *complete* trigger list. Yesterday's call passed only `PostConfirmation`, so `PreTokenGeneration` was dropped.
2. **The function reads the wrong attribute.** The refactor looks for `custom:tenant_id`, but the pool's attribute is `custom:tenant`. The function runs, finds nothing, and adds no claim.

1. Look at the pool's triggers and at a token:

```bash
aws cognito-idp list-user-pools --max-results 10
aws cognito-idp describe-user-pool --user-pool-id <pool-id> --query UserPool.LambdaConfig
aws cognito-idp admin-get-user --user-pool-id <pool-id> --username ava
```

2. Fix `claims.py` (use `custom:tenant`) and deploy it:

```bash
zip claims.zip claims.py
aws lambda update-function-code --function-name cobalt-claims --zip-file fileb://claims.zip
```

3. Set **both** triggers in one call, using the functions' ARNs (`aws lambda get-function-configuration --function-name <name> --query FunctionArn`):

```bash
aws cognito-idp update-user-pool --user-pool-id <pool-id> \
  --policies 'PasswordPolicy={MinimumLength=10,RequireUppercase=true,RequireLowercase=true,RequireNumbers=true,RequireSymbols=false}' \
  --lambda-config PreTokenGeneration=<claims-arn>,PostConfirmation=<welcome-arn>
```

The password policy is passed again on purpose: on AWS, `update-user-pool` resets any setting you do not repeat, and the validator also checks that it did not change.

4. Run `check`. The validator signs ava and ben in again and decodes their ID tokens.

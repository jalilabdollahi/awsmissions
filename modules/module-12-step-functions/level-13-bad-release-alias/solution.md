# Solution

Rolling the alias back to version 1 does not work: version 1 calls `marlin-fx-rates`, a function that no longer exists. Version 2 works technically but its `Gate` compares the converted amount with `100000` instead of `1000` (a cents-versus-euros slip), so nothing ever reaches `SendToReview`. The only good state is a **new version**: fix forward, publish, and point the alias at it.

1. Look at the versions and what the alias serves:

```bash
aws stepfunctions list-state-machine-versions --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:marlin-limit-check
aws stepfunctions describe-state-machine-alias --state-machine-alias-arn arn:aws:states:us-east-1:000000000000:stateMachine:marlin-limit-check:live
aws stepfunctions describe-state-machine --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:marlin-limit-check:1 --query definition
```

2. In `limit-check.asl.json` (`edit`) set `NumericGreaterThanEquals` to `1000`.

3. Publish it as a new immutable version (updating without `--publish` only changes the unnamed "latest" revision, which no alias serves):

```bash
aws stepfunctions update-state-machine \
  --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:marlin-limit-check \
  --definition file://limit-check.asl.json --publish
```

4. Move the alias to the version number returned (for example `:3`):

```bash
aws stepfunctions update-state-machine-alias \
  --state-machine-alias-arn arn:aws:states:us-east-1:000000000000:stateMachine:marlin-limit-check:live \
  --routing-configuration stateMachineVersionArn=arn:aws:states:us-east-1:000000000000:stateMachine:marlin-limit-check:3,weight=100
```

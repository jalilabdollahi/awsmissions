# Solution

In `Parameters`, a key is only treated as a path or intrinsic function when its name ends in `.$`. Two fields were written without it, so their values were stored as plain text:

- `"email": {"S": "$.email"}` stored the literal string `$.email`. Every signup used the same key and overwrote the previous row.
- `"welcomeLine": {"S": "States.Format(...)"}` stored the function call as text.

1. Look at what is really in the table:

```bash
aws dynamodb scan --table-name saffron-subscribers
```

2. In `signup.asl.json` (`edit`) add `.$` to the two keys:

```json
"email": { "S.$": "$.email" },
...
"welcomeLine": {
  "S.$": "States.Format('Welcome to Saffron, {}! Your {} plan starts with {} boxes.', $.fullName, $.plan, $.boxes)"
}
```

3. Update the state machine:

```bash
aws stepfunctions update-state-machine \
  --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:saffron-signup \
  --definition file://signup.asl.json
```

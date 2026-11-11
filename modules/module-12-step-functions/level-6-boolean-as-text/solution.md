# Solution

Two separate problems hide in the one Choice rule `{"Variable": "$.express", "StringEquals": "true"}`:

1. `express` is a JSON **boolean**. `StringEquals` only matches strings, so `true` never equals `"true"` and every parcel falls to `Default`. That is the silent mis-routing.
2. When a parcel has no `express` field, a Choice rule that references the missing path makes the execution fail with `States.Runtime` ("references an undefined value"). Those are the partner parcels.

Fix both in `dispatch.asl.json` (`edit`) by testing for the field first, then comparing as a boolean:

```json
{
  "And": [
    { "Variable": "$.express", "IsPresent": true },
    { "Variable": "$.express", "BooleanEquals": true }
  ],
  "Next": "ExpressLane"
}
```

Then update the state machine:

```bash
aws stepfunctions update-state-machine \
  --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:quillon-dispatch \
  --definition file://dispatch.asl.json
```

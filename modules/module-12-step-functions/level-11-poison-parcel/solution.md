# Solution

Two separate defects, one behind the other.

**1. batchId is missing inside the iterations.** Each Map iteration receives only what `ItemSelector` builds, and the selector contains just the parcel. `AcceptParcel` reads `$.batchId`, which does not exist in the iteration, so every item fails with `States.Runtime`. Inside `ItemSelector`, `$` is the Map state's own input, so the manifest's batch id can be copied in:

```json
"ItemSelector": {
  "batchId.$": "$.batchId",
  "parcel.$": "$$.Map.Item.Value"
}
```

**2. One bad parcel fails everything.** After fixing (1) the malformed parcel raises `MalformedParcel`; with no handler the iteration fails and so does the whole Map. Handle it inside the iteration with a `Catch`, route it to the quarantine queue and end that iteration normally:

```json
"ValidateParcel": {
  "Type": "Task",
  "Resource": "arn:aws:lambda:us-east-1:000000000000:function:kestrel-validate-parcel",
  "ResultPath": "$.validation",
  "Catch": [
    { "ErrorEquals": ["MalformedParcel"], "ResultPath": "$.error", "Next": "Quarantine" }
  ],
  "Next": "AcceptParcel"
},
"Quarantine": {
  "Type": "Task",
  "Resource": "arn:aws:states:::sqs:sendMessage",
  "Parameters": {
    "QueueUrl": "https://sqs.us-east-1.amazonaws.com/000000000000/kestrel-quarantine",
    "MessageBody": {
      "batchId.$": "$.batchId",
      "parcelId.$": "$.parcel.id",
      "reason.$": "$.error.Error",
      "detail.$": "$.error.Cause"
    }
  },
  "End": true
}
```

Then run `aws stepfunctions update-state-machine --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:kestrel-manifest-import --definition file://manifest-import.asl.json`.

Setting `ToleratedFailurePercentage` on the Map would also let the batch succeed, but the bad parcel would just vanish; the validator wants it quarantined.

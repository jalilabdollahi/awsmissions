# Debrief: the ".$" suffix is the switch between text and expression

In the Amazon States Language, `Parameters` (and `ResultSelector`, `ItemSelector`, and so on) is a template. A key such as `"fullName.$": "$.name"` means "evaluate the right-hand side"; a plain key such as `"fullName": "$.name"` means "this is just a string that happens to start with a dollar sign".

The second form is perfectly valid, so nothing complains. The state machine succeeded every time and wrote exactly what it was told to write. That is why this bug lives in data, not in logs.

**Intrinsic functions** only run on `.$` keys too. `States.Format('Hello {}', $.name)` fills each `{}` in order. Others you will meet: `States.JsonToString`, `States.StringToJson`, `States.Array`, `States.ArrayLength`, `States.MathAdd`, `States.JsonMerge`, `States.UUID`, `States.Hash`.

DynamoDB's low-level API wants every number as a *string* inside an `N` attribute (`{"N": "3"}`). Step Functions' DynamoDB integration uses that same JSON, so a number from the input often needs `States.JsonToString($.boxes)` or `States.Format('{}', $.boxes)`. Real AWS rejects a bare JSON number in `N`; the emulator is more lenient, so do not rely on that.

**In real life**
- When a value looks wrong in the destination, read the stored data first. A literal `$.something` in a table or a message is the signature of a missing `.$`.
- A key that is "the same for everyone" (a literal as partition key) quietly turns inserts into overwrites. Test with two different inputs, not one.
- The Workflow Studio "Test state" feature and `aws stepfunctions test-state` show the resolved Parameters without running the whole workflow.

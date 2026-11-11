# Debrief: Choice comparisons are typed

Every comparison operator in a Choice rule belongs to a JSON type: `StringEquals`, `NumericEquals`, `BooleanEquals`, `TimestampEquals`, and so on. The rule only matches if the value at `Variable` has *that* type and satisfies the test. A boolean `true` is not the string `"true"`, and a number `5` is not the string `"5"`. A type mismatch does not raise an error, the rule is simply false, which is why the parcels flowed quietly to the standard lane.

The second symptom is different. If the `Variable` path does not exist in the input at all, Step Functions does not treat it as "no match", it fails the execution with `States.Runtime`. The tool for optional fields is `IsPresent`:

- `{"Variable": "$.x", "IsPresent": false, "Next": ...}` as an early rule, or
- an `And` whose first element is `IsPresent: true`, so the comparison is only evaluated when the field exists.

**In real life**
- Check the type of the producer's field in the actual event (`get-execution-history`, first event) before you choose an operator. APIs often send numbers as strings and flags as `"Y"`/`"N"`.
- Add a Default that is safe for unknown shapes. A Default that sends traffic to the standard path is usually right; one that fails loudly (`Fail` state) is right when a wrong route would cost money.
- Newer workflows can use JSONata (`"QueryLanguage": "JSONata"`) where a Choice condition is an expression such as `{% $states.input.express = true %}`; there a missing field is simply undefined rather than an error.

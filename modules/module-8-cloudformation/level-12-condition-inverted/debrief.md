# Debrief: conditions are named booleans, so name them honestly

A `Conditions` entry is evaluated once per deployment from the parameter values. It can then:

- gate a **whole resource** (`Condition: IsProduction` on the resource),
- choose a **property value** with `Fn::If`,
- gate an **output**,
- be combined with `Fn::And`, `Fn::Or`, `Fn::Not` and `Fn::Equals`.

Because everything flows from one expression, a single inverted comparison flips every dependent decision. Nothing fails: the stack is valid, the deploy succeeds, and the damage is behavioural. That is why this bug usually reaches production.

**What an update does with conditions.** When a condition's result changes on update, resources that become false are *deleted* and ones that become true are *created*. Here that meant the debug topic disappeared and the pager appeared. Read the change set before running such an update; deleting a stateful resource this way is how data gets lost.

**Defensive habits**
- Name conditions after the *meaning* (`IsProduction`) and compare against an `AllowedValues` parameter (`prod`, `dev`) so typos fail early in real CloudFormation.
- Test every branch, as this check does: deploy the template with each environment value to a scratch stack.
- Use `create-change-set` plus `describe-change-set` to see what a condition change will create or remove.
- `UsePreviousValue=true` avoids accidentally flipping a required parameter when you only meant to change the template.

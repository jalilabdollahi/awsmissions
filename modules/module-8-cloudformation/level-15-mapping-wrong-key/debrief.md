# Debrief: Mappings are static lookup tables

`Mappings` is a two-level dictionary baked into the template: `MapName -> TopLevelKey -> SecondLevelKey -> value`. `Fn::FindInMap` reads it during deployment. Keys are plain strings compared exactly, so `us-east1`, `US-EAST-1` and `us-east-1` are three different keys.

**What failure looks like.** Real CloudFormation reports `Template error: Unable to get mapping for RegionSizing::us-east-1::Memory` before it creates anything. A lenient engine may substitute an empty value instead, and the failure surfaces later, as it did here, from the downstream service that rejects the empty property. In both cases the stack ends up rolled back.

**When to use a Mapping**
- Values that depend on a small, known set of keys and never change at deploy time: AMI IDs per region, sizing per environment, account IDs per stage.
- Prefer **Parameters** for values the operator chooses, and **SSM parameter types** (`AWS::SSM::Parameter::Value<String>`) for values that change independently of the template, like "latest AMI".

**Make the miss obvious**
- Give the map a catch-all dimension: key it by an `Environment` or `Tier` parameter with `AllowedValues`, so a bad key is rejected as a parameter error rather than as a mapping miss.
- Keep the table sorted and diff-friendly; add a unit test or `cfn-lint` run to CI. `cfn-lint` verifies that keys used in `FindInMap` exist (`E1011`).
- `Fn::FindInMap` supports a `DefaultValue` with the `AWS::LanguageExtensions` transform, which avoids the hard failure for unknown regions if you deliberately want a fallback.

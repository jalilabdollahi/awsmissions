# Debrief: parameters, defaults and fail-fast inputs

A parameter without a `Default` is a *required input*. CloudFormation validates inputs before it plans anything, which is why you got an immediate `ValidationError` and no stack, not a half-built one.

**Default or explicit value?**
- Put a `Default` where one safe value really exists everywhere (an instance size for dev, a log retention period).
- Leave it out when a wrong silent default would be harmful: an environment name, a branch or account code, anything that ends up in a globally unique name. Forcing the caller to choose is a feature.

**Ways to supply values**
- `--parameters ParameterKey=K,ParameterValue=V` (repeatable).
- `--parameters file://params.json` with a list of `{ParameterKey, ParameterValue}` objects, easy to check into git per environment.
- On `update-stack`, `UsePreviousValue=true` keeps the old value of a parameter you do not want to change.

**Real-life notes**
- `Description` on a parameter shows in the console form; use it to document the expected format.
- Constraints such as `AllowedValues` and `AllowedPattern` give early, readable errors in real CloudFormation, so prefer them over discovering a bad bucket name from a late resource failure.
- Never put secrets in plain parameters. Use `NoEcho` at minimum, and prefer dynamic references to Secrets Manager or SSM.

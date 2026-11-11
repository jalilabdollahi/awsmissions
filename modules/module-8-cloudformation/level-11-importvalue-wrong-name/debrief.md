# Debrief: ImportValue is a string lookup with no safety net

`Fn::ImportValue` takes the exact name of an export and returns its value at the moment the resource is created. A few consequences:

- **Typos fail late.** Nothing validates the name until the resource using it is created, so the error appears as a `CREATE_FAILED` event, not at submit time.
- **Similar names are dangerous.** When production and staging use the same naming scheme, a wrong guess that happens to exist silently wires one environment to the other. Always confirm the *value*, not only that the import resolved.
- **The value is copied, not linked.** If the exporter later changes the value (where CloudFormation allows it), importers that already deployed keep the old one until updated.

**Habits that help**
- Put the environment in the export name via a parameter (`${Env}-audit-topic-arn`) and pass the same parameter to consumers, so they cannot mix environments.
- Build the import name with `!Sub "ledgerline-${Env}-audit-topic-arn"` rather than typing it per environment.
- `aws cloudformation list-exports` is the quickest way to discover names; filter it with `--query "Exports[?contains(Name,'audit')]"`.
- A consumer that takes the value as a *parameter* (set by your pipeline from a `describe-stacks` output) is easier to test than one that imports directly.

# Debrief: versions are snapshots, aliases are movable pointers

Three concepts, three levels of "how fixed is the code":

- **`$LATEST`**: the working copy. Every `update-function-code` changes it immediately.
- **Version** (`1`, `2`, `3`...): an immutable snapshot of code *and* configuration, created by `publish-version`. Numbers are never reused.
- **Alias** (`prod`, `staging`): a named pointer to one version (or to two, with weighted routing for canary releases). Callers use `function:alias`, and you promote or roll back by moving the pointer.

An alias can be created pointing at a version number that does not exist (as this mission shows); the failure then appears only at invoke time as `Function version not found`. In the other direction, Lambda refuses to delete a version that an alias still references.

**Why not point prod at `$LATEST`?** Because whatever is uploaded next goes live instantly, un-reviewed. In this story `$LATEST` carries the unapproved rounding experiment, so a shortcut fix would have silently overcharged customers. The checker invokes the alias and looks at the *behaviour*, not just at the version number, to catch that.

**Release notes in descriptions.** The `--description` on `publish-version` is the only free-text field on a version. Using it for "what changed and who approved it" turns `list-versions-by-function` into an audit log.

**In real life**
- Deploy with `update-function-code --publish`, run smoke tests against the new version, then `update-alias`. Rollback is the same command with the old number.
- Use `--routing-config AdditionalVersionWeights={"3"=0.05}` for a 5% canary on an alias.
- Event sources, API Gateway integrations and resource policies can be attached to an alias ARN, so the pointer move re-targets all of them at once.

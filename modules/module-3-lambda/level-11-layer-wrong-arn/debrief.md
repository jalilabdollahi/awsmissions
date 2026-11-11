# Debrief: layers are immutable versions that you pin

A **layer** is a zip that Lambda unpacks under `/opt` next to your function. For Python everything below `python/` lands on `sys.path`; for Node.js it is `nodejs/node_modules`. Layers let teams share dependencies and rules without repackaging each function.

Rules that matter:
- **Versions are immutable.** Publishing again creates version 2; version 1 never changes. Functions reference a *version ARN* (`...:layer:riskkit-core:1`), so publishing a new version updates nobody. You must update each function that should use it. That is the design: no surprise breakage, but also no automatic rollout.
- **`--layers` replaces the full list** (up to 5 layers). Passing only the new riskkit ARN would silently detach `tracekit-logging` and the failure would just move to `import tracekit`.
- Layer content is merged in the order given, later layers overwrite files of earlier ones.
- The unzipped function plus all layers must stay below 250 MB.

**Reading the error:** `cannot import name 'velocity_penalty' from 'riskkit.rules'` means the layer was found (otherwise it would be `No module named 'riskkit'`) but it is the wrong version. A *non-existent* layer version is rejected when you configure the function, with `Layer version ... does not exist`.

**In real life**
- Give each version a clear `--description` (a changelog line) so `list-layer-versions` is a usable audit trail.
- Share layers across accounts with `add-layer-version-permission`, and roll out new versions through your deploy pipeline with a test invocation.
- `aws lambda list-functions` plus a `jq` filter on `.Layers` finds every function still on an old version.

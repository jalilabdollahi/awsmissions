# Debrief: runtimes age out

A Lambda runtime is a managed language environment: operating system image, interpreter and the Lambda runtime interface client. AWS retires them when the upstream language reaches end of life.

What a retired runtime means in practice:
- **Deprecation phase 1:** you can no longer create new functions with it; existing ones keep running (and get no security patches).
- **Phase 2:** you can no longer update the function's code or configuration either.
- Emulators and the real service differ in how they surface this. Here the failure appears at invoke time as `Lambda.InitError: The runtime parameter python3.6 is not supported`.

Switching the runtime is a one-line configuration change, but the code has to be compatible. Moving *backwards* (to python3.9, say) trades the `InitError` for `Runtime.UserCodeSyntaxError`, because `match` statements only exist from Python 3.10. Moving *forwards* across major language versions can break dependencies compiled for the old version.

**In real life**
- Subscribe to AWS Health notifications and the "Lambda runtime deprecation" emails; they list affected functions per Region.
- `aws lambda list-functions --query "Functions[].[FunctionName,Runtime]"` across Regions gives you the inventory.
- Prefer the newest runtime your dependencies support, and pin it in your IaC so upgrades are reviewed changes, not surprises.
- Test an upgrade on a published version or alias first (a later mission covers aliases).

# Debrief: drift, and which way to reconcile it

**Drift** is any difference between what a stack's template says and what its resources actually are. It is almost always created by humans fixing things at 2 a.m., and it is dangerous because the next deploy may silently revert the fix, or fail in a confusing way.

**Detecting it in real AWS**
- `aws cloudformation detect-stack-drift --stack-name X`, then `describe-stack-drift-detection-status` and `describe-stack-resource-drifts`, show per-property expected versus actual values.
- AWS Config and the console's *Detect drift* button run the same check on a schedule.
- This emulator does not implement the drift API, so the mission asks you to diff manually with `get-template` and the service's own `describe/get` calls. The skill is identical: know both sides.

**Which way to reconcile**
1. *Reality is right* (this mission): copy the new values into the template and update. The update is effectively a no-op for the real resources but records the truth, so future deploys keep it.
2. *The template is right*: revert the resource by hand, or run an update that changes the property so CloudFormation rewrites it.
3. *Neither*: decide deliberately, ideally in a pull request.

**Traps**
- `update-stack` with an unchanged template does nothing (`No updates are to be performed`); it does not "refresh" drifted resources.
- Some drift is invisible to a template diff: properties CloudFormation does not manage, such as extra tags on resources outside the stack or settings of unsupported types.
- Reduce drift at the source: restrict who can edit stack-managed resources, require break-glass access with an alert, and schedule drift detection in production.

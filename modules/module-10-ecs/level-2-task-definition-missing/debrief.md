# Debrief: task definitions are versioned records in the account

A task definition is not a file in your repo; it is an object registered with ECS. Every `register-task-definition` for a family creates the next numbered revision (`harbor-web:1`, `:2`, ...), and services point at one specific revision. Registering the same JSON again creates a new revision rather than editing an old one.

The error you saw (`Unable to describe task definition`) means the referenced `family:revision` is not registered here: new account, another region, or somebody deregistered it.

Real-world tips:
- Reference a family without a revision (`--task-definition harbor-web`) to get the latest ACTIVE revision, or pin a revision for reproducible deploys.
- Deregistering marks revisions INACTIVE, they are not deleted. Running tasks keep working.
- Keep the JSON in git and register it from CI so every environment gets the same spec.
- `cpu`/`memory` must be a valid Fargate pair (see the next level for what happens when they are not).

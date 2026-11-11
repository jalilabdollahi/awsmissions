# Debrief: when the image cannot be pulled, nothing else matters

ECS pulls the image before any of your code exists, so a bad reference never produces application logs: the task goes straight to STOPPED, and the only trace is `stoppedReason` on the task (`CannotPullContainerError` in real AWS, "not found" for a missing tag, "pull access denied" for permissions or a wrong repository).

The reasons to check, in order:
1. Does the tag or digest exist? (typo, un-pushed build, retention policy deleted it)
2. Is the repository URI right (account id, region, repo name)?
3. Can the task reach the registry? (public IP or NAT/VPC endpoints, plus an execution role for ECR)

Real-world tips:
- Never hand-edit image tags during an incident without writing the change back to the pipeline. A single source of truth (here a Parameter Store value, in practice a CI artefact) prevents drift.
- Pin immutable digests (`repo@sha256:...`) for production; mutable tags like `latest` make rollbacks ambiguous.
- Enable ECR tag immutability and lifecycle policies carefully: an aggressive lifecycle rule is a classic cause of "image not found" weeks later.

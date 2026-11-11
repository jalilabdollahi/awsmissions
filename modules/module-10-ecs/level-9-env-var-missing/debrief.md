# Debrief: reading a crash loop

A container that dies immediately gives the scheduler an easy job and you a confusing view: ECS keeps launching replacements, `runningCount` stays at 0, and the stopped-task list grows. The investigation always goes the same way:

1. `describe-tasks` on a STOPPED task: `stoppedReason` and the container's `exitCode`. "Essential container in task exited" with exit code 1 or 2 means the application chose to quit (versus 137 = killed, OOM).
2. The container's logs: the app told you why. This is why every container needs an `awslogs` (or other) log configuration.
3. Then the configuration: environment variables, secrets, command, mounted files.

Notes:
- Task definition revisions are immutable. "Fix the variable" really means "register revision N+1 and update the service".
- Configuration that differs per environment belongs in `environment` (non-secret) or `secrets` (Secrets Manager / SSM), never baked into the image.
- Fail fast, loudly and with a clear message, exactly like this start-up script does: it turns a one-hour mystery into a thirty-second fix.

# Debrief: INC-6120, ledger-web will not start

## Root causes
1. **Unreachable image registry.** The task never gets to run code; ECS reports `TaskFailedToStart` with a pull error in `stoppedReason`.
2. **Wrong environment variable name.** `DATABASE_HOST` vs `DB_HOST`. The wrapper guard did exactly what it was written to do: exit 3 rather than serve a broken page.
3. **Service scaled to zero and pinned to the broken revision.** Fixing the task definition alone changes nothing until the service is told to use it.

## Timeline
- Weekend: the internal registry mirror goes down. Nobody notices since existing tasks keep running.
- Mon: rollback drill scales `ledger-web` to 0 and the env var is "normalised" in revision 1.
- Wed 09:00: month-end close; no task will start; INC-6120.

## Reading ECS failures
There are two distinct failure shapes. A task that **never starts** has `stopCode=TaskFailedToStart` and a `stoppedReason` (image pull, secrets, networking, role). A task that **starts and exits** shows a container `exitCode` and its logs; code 3 here came from the wrapper's own guard. Service events describe scheduling problems, but the stopped task is where the real reason lives.

## Lessons
- Mirror images into a registry you control and monitor it; "a dependency down for the weekend" should page someone.
- Fail fast in entrypoints on missing configuration, and print which variable is missing so the next engineer does not need a debugger.
- Keep task definitions in code; hand-editing revisions during drills produces untraceable differences.
- After a drill, restore desired counts (or use autoscaling with min capacity) so a scale-to-zero cannot linger.

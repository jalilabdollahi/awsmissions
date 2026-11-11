# Debrief: the path is part of the ARN

IAM names are not flat. Users, groups and roles can sit under a **path** that works like a folder: `/contractors/`, `/division_abc/engineering/`. The path becomes part of the ARN:

| What you created | ARN |
|---|---|
| `--user-name kim` | `arn:aws:iam::123456789012:user/kim` |
| `--user-name kim --path /contractors/` | `arn:aws:iam::123456789012:user/contractors/kim` |

Policy `Resource` entries are matched against the full ARN, so `user/${aws:username}` and `user/contractors/${aws:username}` are different resources. The variable `${aws:username}` expands to the **name only**, never the path.

Two details bite people:

- Role paths behave the same way in the ARNs of `iam:PassRole` and `sts:AssumeRole` policies. Note, though, that the `RoleName` in API calls and in `AssumeRole`'s *session ARN* leaves the path out.
- Moving something to a different path means recreating it, so pick paths deliberately.

**In real life**
- Paths enable neat delegation: `Resource: arn:aws:iam::*:user/contractors/*` lets a manager administer all contractors without touching staff.
- Use `user/*/${aws:username}` if you must support mixed paths, but note it also requires some path segment, so path-less users need their own entry.
- When a policy that worked on test accounts fails on real ones, compare the **full ARN** from `get-user` or `get-role` with the policy's Resource.

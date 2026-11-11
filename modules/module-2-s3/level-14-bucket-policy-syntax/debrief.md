# Debrief: valid JSON is not a working policy

A linter checks *syntax*. Whether a policy grants anything depends on whether its elements match the real request. Three classic ways to write a policy that is valid yet inert appeared here:

1. **Wrong operator for the value.** `StringEquals` is an exact comparison, so `"outbound/*"` matches only a prefix that literally contains an asterisk. Wildcards require `StringLike`. The prefix condition on `ListBucket` is the standard way to let someone list one folder, and the standard place to get this wrong.
2. **Misspelled action.** `s3:GetObjects` looks right and is simply a different, non-existent action. Real AWS rejects unknown actions in IAM policies in some contexts and quietly stores them in others; never count on a warning.
3. **Wrong account in the principal.** A principal in another account means "that account's user", not "our user of the same name". For cross-account access both sides must allow it.

**Why the "no prefix" probe matters**
A condition such as `s3:prefix` on `ListBucket` is what stops the partner from enumerating `internal/`. Replacing it with a bare `ListBucket` grant would have fixed the symptom and exposed the catalogue's file names.

**In real life**
- Use IAM Access Analyzer's policy validation and policy generation; they catch non-existent actions and over-broad grants.
- Test policies by *acting as the principal* (or `simulate-principal-policy` for identity policies) for both the positive and the negative cases.
- Keep one statement per intent with a descriptive `Sid`, like this policy does. It makes review and debugging far quicker.

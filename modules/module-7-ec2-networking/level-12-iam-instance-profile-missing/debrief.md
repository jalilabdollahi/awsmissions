# Debrief: roles reach instances through instance profiles

IAM roles are assumed by a *principal* named in the role's trust policy. For EC2 that principal is the service `ec2.amazonaws.com`, and the delivery vehicle is an **instance profile**, a thin container that holds one role. The instance fetches short-lived credentials from the metadata service (IMDS) and SDKs find them automatically, so no access keys ever need to sit on disk.

Two independent things must be true: the profile is attached to the instance, and the role trusts EC2. Copying a trust policy from a Lambda role is a classic cause of the second failure.

Real-world tips:
- The console creates the profile for you when you create an EC2 role; the CLI and CloudFormation do not.
- `associate-iam-instance-profile` works on running instances: no relaunch needed. Replacing a profile uses `replace-iam-instance-profile-association`.
- `iam simulate-principal-policy` verifies what the role can do without running the app.
- Require IMDSv2 (`HttpTokens=required`) so SSRF bugs cannot steal the role's credentials easily.

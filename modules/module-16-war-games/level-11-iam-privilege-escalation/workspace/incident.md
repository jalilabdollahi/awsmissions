# Pen-test finding PT-2026-014 (CRITICAL): CI role can become account admin

Quasar Fintech. External red team report, excerpt.

> Starting from the credentials of the CI pipeline user (`qf-ci-bot`, which can
> assume the role `qf-ci-deployer`) we obtained full administrator access to the
> AWS account within minutes, using only permissions already granted to the
> deploy role. We found several independent paths. We did not need to exploit
> any vulnerability in AWS.

## What the CI role is *supposed* to do (keep working)
- Deploy new code to Lambda functions named `qf-*` (`lambda:UpdateFunctionCode`,
  `lambda:UpdateFunctionConfiguration`, `lambda:CreateFunction`).
- When creating a function, give it the standard execution role
  `qf-svc-lambda-exec` and nothing else.
- Upload build artifacts to `s3://qf-build-artifacts`.

## What it must never be able to do
- Create IAM roles or change their permissions, including its own.
- Hand any other role (such as `qf-platform-admin-role`) to a service.
- Mint credentials for another identity (`qf-platform-admin` is a human admin).

## Existing wiring
- `qf-ci-bot` assumes `qf-ci-deployer` (inline policy `ci-deploy`).
- Pipelines must not break: tonight's release still has to ship.

## Reviewer notes
"The policy was written as 'give the pipeline whatever it asks for' in 2024."

# Debrief: INC-4417, partner catalogue API

## Root causes
| Layer | Fault | What a partner saw |
|---|---|---|
| Stage | Only `staging` was deployed | `404 Stage not found` (BookBarn) |
| Integration | URI still named `qm-catalog-api-v1` | `404 Function not found` after the stage was fixed |
| Usage plan | Plan listed `staging`, not `prod` | `403 Forbidden` (Paperfox) once the stage existed |
| Lambda | Reserved concurrency 0 | Throttling / 5xx for the mobile app |

## Timeline
- 14:02 migration; Terraform covered the API and function, the stage, key plan and concurrency were done by hand.
- 14:20 three partners report three different errors. The ticket initially gets split into three tickets.
- 15:30 someone connects the dots: the errors are the same incident peeled one layer at a time.

## How API Gateway evaluates a call
Stage lookup, then method (API key required?), then usage plan membership for that key and stage, then the integration. Only then does Lambda see the request, and it applies its own concurrency limit. Each layer gives a different status code, so the error you get tells you which layer you have reached, not that the layers behind it are healthy.

## Lessons
- Editing an API does nothing until you create a deployment; include "deploy" in every runbook for API changes.
- Put API key plans, stages, integrations and function names in one Terraform/CDK module so renames propagate.
- Reserved concurrency 0 is a valid kill switch; track it with an alarm on `Throttles`.
- After any migration run a synthetic partner request through the real URL, with key, as the acceptance test.

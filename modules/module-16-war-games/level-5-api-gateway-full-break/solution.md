# Solution

1. **Integration.** `GET /books` still targets `qm-catalog-api-v1`. Re-run `put-integration` with the ARN of `qm-catalog-api`.
2. **Stage.** The only deployment is to a stage called `staging`, but the partner contract is `/prod`. Create a deployment to `prod` (after fixing the integration, so prod contains the corrected method). Do not switch the key requirement off and do not rename the contract.
3. **Usage plan.** `qm-partners` covers `staging` only, so the key is not valid on `prod`. Add the prod stage with `update-usage-plan --patch-operations op=add,path=/apiStages,value=<api-id>:prod`.
4. **Concurrency.** Reserved concurrency 0 throttles every call. `aws lambda delete-function-concurrency --function-name qm-catalog-api`.

`check` triages each layer, then calls `/prod/books` once with the partner key (expecting 200 and a non-empty catalogue) and once without a key (expecting rejection).

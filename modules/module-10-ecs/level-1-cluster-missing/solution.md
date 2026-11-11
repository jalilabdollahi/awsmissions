# Solution

`run-task` needs an existing cluster. The cleanup removed `ledgerly-batch`, so the call fails with `ClusterNotFoundException`. Tasks and task definitions are not part of the cluster, so the registered `nightly-report` definition is still fine.

```bash
aws ecs create-cluster --cluster-name ledgerly-batch
bash run-report.sh
```

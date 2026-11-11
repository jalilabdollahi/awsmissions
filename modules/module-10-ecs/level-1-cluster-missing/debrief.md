# Debrief: a cluster is just a namespace, but you must create it

An ECS cluster is a logical grouping of tasks and services. With Fargate there are no servers behind it, so creating one is instant and free; it is only the name that services and `run-task` calls refer to. If it is missing you get `ClusterNotFoundException` and nothing is scheduled.

Task definitions are independent of clusters: they are versioned (`family:revision`) and can run anywhere. That is why recreating the cluster is enough here.

Real-world tips:
- Cleanup scripts that delete "empty" clusters will happily delete the one a cron job needs at 02:00. Tag clusters with an owner and add alarms on failed `RunTask` events.
- Define clusters in infrastructure as code so they come back with a single apply.
- Do not confuse similarly named clusters (`ledgerly-staging` here): the name in the job is what counts.

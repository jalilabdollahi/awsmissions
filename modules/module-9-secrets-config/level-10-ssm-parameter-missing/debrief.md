# Debrief: Parameter Store names are flat strings that look like paths

An SSM parameter is identified by its full name. Names that start with `/` and contain further slashes form a **hierarchy** by convention, which gives you:

- `get-parameters-by-path --path /corvid/checkout` to fetch a whole service's config in one call,
- IAM policies scoped to a subtree (`parameter/corvid/checkout/*`),
- one place to see the settings of each service and environment (`/<company>/<service>/<setting>`, or `/<env>/<service>/...`).

There is nothing to create for the "folder" itself; asking for a path that holds no parameters just returns an empty list, while asking for a missing *name* gives `ParameterNotFound`.

**Choosing a type**
- `String` for non-sensitive settings such as hosts, ports and feature flags.
- `StringList` for comma-separated lists.
- `SecureString` for anything secret, encrypted with a KMS key.

**Parameter Store or Secrets Manager?** Parameter Store is free for standard parameters, simple and hierarchical, and fine for configuration. Secrets Manager adds rotation, cross-region replication and a per-secret price. A common split: connection *details* in Parameter Store, the *password* in Secrets Manager.

**Tips**
- Overwriting needs `--overwrite`; every write creates a new numbered version, kept in history.
- Treat missing config as a deployment problem: provision parameters in the same pipeline (CloudFormation `AWS::SSM::Parameter`) as the service that reads them, and fail the deployment if one is absent.

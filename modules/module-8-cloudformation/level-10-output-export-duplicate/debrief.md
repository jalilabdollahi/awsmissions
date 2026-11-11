# Debrief: exports are a shared namespace

`Outputs` with an `Export` publish a value for other stacks to consume with `Fn::ImportValue`. Two rules matter:

1. **Names are unique per account and region.** A second stack cannot create an export with a name already in use, and you cannot rename an export in place if anything imports it.
2. **Importers bind by name.** The consumer stores nothing but the string, so changing the exporter's value, or deleting the exporter, can break running stacks. Real CloudFormation blocks updates and deletes of an export while it is imported.

Copy-pasting a template and forgetting to change exported names is the usual way to meet rule 1. The failed stack in this level shows the second consequence of a failed create: it must be deleted before its name can be used again.

**Naming conventions that avoid trouble**
- Prefix exports with the stack or service name: `quayside-network:AssetsBucket`, or `${AWS::StackName}-AssetsBucket` so a copied template renames itself.
- Treat exports as a public API: version them, document them, avoid renaming.

**Alternatives to exports**
- SSM parameters written by the producing stack and read by consumers: no hard dependency, easy to change.
- Passing values as parameters from a pipeline or a parent stack (nested stacks).

**In real life** check who imports an export before touching it with `aws cloudformation list-imports --export-name NAME`.

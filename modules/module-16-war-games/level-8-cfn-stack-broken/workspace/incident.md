# CHG-2207 / INC-3318 - orders stack refuses to update

Cobalt Retail, platform infra. Change CHG-2207 moved the order ledger from the
monolith into its own CloudFormation stack, `cobalt-orders`.

## What happened
1. The stack was created from `orders-stack.yaml` (copy in your workspace).
2. Creation ended in `CREATE_FAILED`, but not before it had created the table
   and function. Finance then started writing real ledger entries into
   `cobalt-ledger` (see entry `E-1`; there will be more by Monday).
3. The deploy bot now reports "stack not in an updatable state".
4. A junior engineer proposed: "just delete the stack and recreate it".

## Facts
- Another stack, `cobalt-core` (owned by the legacy team), exports the name
  `cobalt-orders-queue-arn`. Its consumers still depend on it. It must not be
  deleted or changed.
- Export names are unique per region.
- The function should answer `{"status": "ledger-ok", ...}` when invoked.
- A stack delete removes every resource in it unless the resource says
  otherwise.

## Acceptance
`cobalt-orders` in a healthy `*_COMPLETE` state, the ledger data intact, the
function working, and the stack safe to delete without losing the ledger.

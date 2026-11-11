# Debrief: the handler string is a pointer

`Handler` is a string with two halves: where Lambda should `import` code from, and which exported function it should call. For Node.js it is `file.exportName` (the file extension is dropped, and a folder is allowed: `src/relay.sign`). For Python it is `module.function`, for Java `package.Class::method`.

When the pointer is wrong the symptoms depend on which half missed:

| Mistake | What you see |
|---|---|
| File not in the package | `Runtime.ImportModuleError: Cannot find module 'index'` |
| File found, name not exported | `Runtime.HandlerNotFound` |
| Wrong but valid export | Runs fine and returns the wrong thing |

That last row is the dangerous one, and it is why this mission's checker verifies the HMAC signature instead of only looking for "no error". Here `relay.ping` would turn the errors green without relaying a single order.

**Why it happened:** a pipeline template hard-coded `index.handler`, a common Node.js default, regardless of what the package actually contained.

**In real life**
- Keep the handler in the same repo as the code (SAM `Handler:`, Terraform `handler =`) so they change together.
- `.mjs` files or `"type": "module"` mean ES modules (`export`), otherwise Node expects CommonJS `exports.handler = ...`.
- A smoke-test invoke in the deploy pipeline catches this class of mistake before users do.

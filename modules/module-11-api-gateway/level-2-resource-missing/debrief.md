# Debrief: URLs are a tree of resources

In a REST API every path is a node in a tree built from **resources**: `/` has a child `notes`, which has a child `{noteId}`. Methods hang off nodes. `/notes` having a GET says nothing about `/notes/n-204`. Without a matching node, API Gateway never reaches your code; real AWS answers `{"message":"Missing Authentication Token"}` with HTTP 403, a famously misleading message that actually means "no such route".

Path parameters:
- A path part in braces, `{noteId}`, matches any single segment and exposes it as `event.pathParameters.noteId` for proxy integrations (or `$input.params('noteId')` in mapping templates).
- Name matters. If the resource is `{id}` the Lambda sees `id`, not `noteId`.
- A greedy `{proxy+}` matches the rest of the path (multiple segments) and is how you forward an entire sub-tree to one function. It is flexible but you give up per-route methods, authorizers and throttling; it also gives you a parameter called `proxy`, not `noteId`.
- Static resources win over parameters: `/notes/recent` takes precedence over `/notes/{noteId}`.

Deployment: an edit to resources, methods or integrations affects clients only after a new deployment to the stage on real AWS (`create-deployment --stage-name v1`). Forgetting this is the number one cause of "I fixed it, it still fails".

Tips: model a resource tree in IaC, never by hand; make one function per resource group only if the code stays cohesive; and test 404 behaviour of your function separately from route-missing 403 responses.

# Debrief: mapping templates are code that fails quietly

With a non-proxy (`AWS`) integration API Gateway builds the backend request from a **Velocity (VTL)** template. `$input.path('$.productCode')` evaluates a JSONPath against the incoming body. Ask for a path that does not exist and VTL gives you an empty string, not an error. The backend then receives well-formed JSON with empty values, and fails (or worse, succeeds) in a confusing way, far from the real cause.

Details that cause real incidents:
- **Types**: `"qty": "$input.path('$.quantity')"` produces a string; `"qty": $input.path('$.quantity')` produces a number. Quote only what must be a string.
- **Escaping**: free text interpolated raw breaks the JSON as soon as it contains a quote or a newline (and is an injection vector). `$util.escapeJavaScript(...)` makes it safe; use `$input.json('$.field')` when you want the original JSON fragment preserved as is.
- **Whole body**: `$input.json('$')` forwards the body unchanged; `$input.params('name')` reads path, query or header parameters.
- **Passthrough**: `passthroughBehavior NEVER` rejects a body whose content type has no template (415) instead of sending it unmodified.
- **Contract drift**: when a public field is renamed, the template has to change with it. Keep a request-validation model on the method so a bad body is rejected with 400 before it reaches the template.

Debugging: enable execution logging and data trace on a stage, or use the test-invoke feature (`aws apigateway test-invoke-method`) to see the transformed request. Locally, call the function directly with the payload you think the template produces and compare.

When to avoid templates: if you find yourself writing loops and conditionals in VTL, use a Lambda proxy integration and keep the logic in tested code.

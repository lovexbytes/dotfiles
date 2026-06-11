# Context Rules: Dependencies and Supply Chain Agent

| Trigger in diff | What to load | How | Why |
|---|---|---|---|
| `go.mod`, `go.sum`, `vendor/modules.txt`, or `go.work` changed | Imports added/removed in changed Go files + CI build commands | Search for new module import path and build/test commands | Verify dependency is used and build graph is reproducible |
| `replace`, pseudo-version, local path, or private module added | Module source, CI environment, release build config | Use File Access instructions from your prompt | Local/fork dependency can break CI or release reproducibility |
| `go` or `toolchain` directive changed | Dockerfile, CI image, Makefile, setup docs | Use File Access instructions from your prompt | Toolchain must match builder/runtime |
| Dockerfile or CI image changed | `go.mod`, Makefile, lint/test/build jobs | Use File Access instructions from your prompt | Image/tool drift can break builds or change generated output |
| Generator config or generated files changed (`buf`, `sqlc`, OpenAPI, mocks) | Source contract + generator version/config + generated output | Use File Access instructions from your prompt | Source, generator, runtime, and output must stay aligned |
| Install script downloads binary or script | Version pinning and checksum verification | Use File Access instructions from your prompt | Unpinned executable download is supply-chain risk |

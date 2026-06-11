# Codex agent defaults
- Prefer MCP gopls tools for Go code: use `go_symbol_references` for refs/callers, `go_search` for symbol discovery, `go_package_api` for APIs, `go_file_context` for cross-file context, and `go_workspace` for layout.
- Only fall back to plain text searches (`rg`, etc.) when gopls is unavailable or the query is non-Go text/README/config content; mention the fallback in the response.
- When the user asks for “find”, “where is”, “who calls”, or interface implementation questions about Go code, default to gopls instead of grep.
- Keep the user informed if gopls errors or returns empty results and offer an alternative search. 
# Review skills
- Use `go-review` when the user asks to review local uncommitted changes, current working tree changes, or a pre-commit diff against a target branch.
- Use `go-review-branch` when the user asks to review committed changes on the current branch against a target branch.
# Code style
- For Go production code work, use the `go-style` skill when creating, modifying, reviewing, or refactoring hand-written Go code. Let repo-local conventions and more specific skills take precedence for tests, env config, sqlc/DB work, NATS jobs, generated files, or command-only tasks.
- For repo/app config work in Go, especially `config.go`, environment variables, `mapstructure` tags, viper, or servkit `config.Loader`, use `go-env-cfg` before creating, editing, or reviewing the config. Verify the derived env var names from struct nesting and tags.
# Testing
- For Go test work, use the `go-tests` skill when creating, modifying, reviewing, debugging, or choosing coverage for Go tests, and when a Go behavior change needs test updates. Follow nearby test patterns first, then choose table tests, BDD/gomock, or integration coverage based on the boundary under test.
# DB skills
- Use `db-postgresql` for Postgres schema/data inspection, Docker Compose Postgres startup, migrations, indexes, enums, backfills, or migration SQL files; derive DB name/credentials from repository Compose/config. Pair with `db-sqlc` when repository SQL or generated sqlc output changes.
- When asked to create or modify a query, first check whether the current project has a sqlc layout, such as `sqlc.yaml`/`sqlc.yml`, query SQL files, and generated Go output. If present, use `db-sqlc`: edit query SQL, regenerate affected sqlc output, and keep generated diffs with the query change. If absent, do not assume sqlc; follow the repository's existing data-access pattern unless the task explicitly asks to introduce sqlc.
# Documentation skills
- Use `indexing-codebase-repos` when the user asks to build, refresh, or extend a per-repo codebase index; when onboarding to an unfamiliar repo; when mapping domains, layers, entrypoints, integrations, or deployment config; or when code changes may invalidate existing docs under `docs/`. If a change alters behavior, boundaries, entrypoints, integrations, config, observability, ownership, or where-to-change guidance, update the relevant index docs in the same change.
- Use `mermaid-diagrams` only when the user explicitly asks to draw/create a diagram or asks for Mermaid syntax. Exception: an active documentation skill such as `write-adr` may use it when a diagram would materially improve that document.
- Use `write-adr` only when the user explicitly asks to write, draft, create, update, or produce an ADR / Architecture Decision Record.
# Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution
- When spawning subagents, do not set `model` in `spawn_agent`; subagents must inherit the current session model. Set `model` only if the user explicitly requests a different model.

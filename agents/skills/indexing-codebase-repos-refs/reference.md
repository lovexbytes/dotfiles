# Repo index — full checklist

Use this when creating or auditing `docs/` index files. Every bullet should be satisfied somewhere in the layered docs (not necessarily every file for every bullet—use judgment, but **no omissions** of the concern).

## docs/index.md

- [ ] Service (or library) **name** and one-paragraph **purpose**
- [ ] **In scope / out of scope** (boundaries; what this repo does *not* own)
- [ ] **Generated** block: UTC ISO-8601 timestamp, `git rev-parse HEAD` (full SHA)
- [ ] **Quick orientation**: primary language(s), build tool, where tests live
- [ ] For Go repos, **MCP navigation** note if gopls is available: prefer `go_workspace`, `go_search`, `go_package_api`, `go_symbol_references`, `go_file_context`, and `go_diagnostics` for symbol-level follow-up; keep repo-relative paths and omit local server IDs / user paths
- [ ] **Table of contents** with links to all sibling pages under `docs/`
- [ ] **Domain index**: link each `docs/domains/*.md` with one-line summary
- [ ] Useful top-level docs (`developer-guide.md`, ADRs, rollout docs, feature specs) linked or explicitly marked obsolete / archival
- [ ] Optional: link to sibling repos if known (placeholder for future global index)

## docs/entrypoints.md

- [ ] Processes: HTTP, gRPC, workers, schedulers, CLI, batch
- [ ] For each: binary or module path, how it is started locally and in prod
- [ ] Docker image / chart entry if applicable
- [ ] Background job commands, queues, NATS streams/consumers, or cron schedules if present

## docs/layers.md

- [ ] Diagram or bullet **layer list** (e.g. transport → application → domain → persistence)
- [ ] **Allowed dependencies** between layers; forbidden directions
- [ ] Notable patterns (DDD, hexagonal, etc.) only if actually used

## docs/domains/<domain>.md (repeat per domain)

- [ ] **Domain purpose** and boundaries vs other domains
- [ ] **Core concepts** (entities, aggregates, value objects) — names only + where defined in code
- [ ] **Primary workflows** (commands/events) with **package paths**
- [ ] **Persistence** (tables, collections) if any — logical names + migration location
- [ ] **Invariants / rules** that code enforces
- [ ] **Failure modes** and how they surface (errors, retries)
- [ ] **Verification**: focused tests or make targets for the domain

## docs/integrations.md

- [ ] Each external system: purpose, client location, sync vs async
- [ ] Auth method (mTLS, API key name, OAuth) without secrets
- [ ] Timeouts, retries, idempotency keys where relevant
- [ ] Generated contract packages / regeneration commands when the repo exposes service contracts

## docs/config-and-secrets.md

- [ ] Env vars table: name, meaning, default, required in prod
- [ ] Config files and formats (yaml, toml, etc.)
- [ ] Feature flags: where defined, how toggled per env
- [ ] Secrets: **reference only** (vault path pattern, K8s secret name), never values

## docs/observability.md

- [ ] Logging: libraries, correlation IDs, sample log queries
- [ ] Metrics: key metric names or dashboards
- [ ] Tracing: service name in tracer, critical spans
- [ ] Alerts/on-call hooks if known

## docs/deployment-and-infra.md

- [ ] **Per environment** (dev/stage/prod or your names): chart, values file path, namespace pattern
- [ ] Terraform roots/modules that affect this service (paths)
- [ ] Migrations/job hooks on deploy
- [ ] Resource knobs (CPU/mem) only if they matter for operators

## docs/ownership.md

- [ ] Owning team or role
- [ ] Chat/channel, issue tracker project
- [ ] Escalation path if different from default

## docs/where-to-change.md

- [ ] Rows: **Task type** | **Symptom** | **Start here (path)** | optional **Navigation hint** | **Verify with** (make target, test file, or manual check)
- [ ] Include cross-cutting concerns: auth, pagination, DB migration, API versioning
- [ ] For Go symbol-heavy areas, include enough stable package/file pointers that an agent can run targeted gopls lookups without scanning the repo from zero

## Global index (future)

When maintaining multiple repos, add a separate catalog (outside this skill’s per-repo layout) that maps **logical capability → repo → `docs/index.md`**. Do not duplicate domain detail in the global file—link only.

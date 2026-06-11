---
name: indexing-codebase-repos
description: >-
  Use when the user asks to build, refresh, or extend a per-repo codebase index;
  when onboarding to an unfamiliar microservice, library, or infra-heavy repo;
  when mapping domains, layers, entrypoints, integrations, or deployment config;
  or when changes may invalidate existing docs under docs/.
---

# Indexing codebase repos

## Overview

Produce a **layered, human-readable map** under `docs/` so agents and humans can navigate logic without full-repo scans. The hub is **`docs/index.md`**; detail lives in linked files, usually **one file per domain** plus shared cross-cutting pages.

The index is a **compass, not an inventory**:

- Prefer package/domain boundaries, workflows, invariants, entrypoints, and "where to change" pointers.
- Avoid dumping every file, type, function, route, or generated API.
- Give enough path-level detail that the next agent can run targeted gopls MCP lookups, `rg`, tests, or file reads instead of re-discovering the service from zero.
- Keep output portable for shared team use: repo-relative paths, package paths, and tool names only; do not include machine-specific absolute paths, user home directories, or local MCP server IDs.

**Core rule:** If a change alters behavior, boundaries, entrypoints, integrations, config, observability, ownership, or “where to change X,” **update the relevant index files in the same change**—do not rely on a separate “refresh index” command for that.

## When to use

- New repo or no `docs/index.md` yet → create the full structure.
- User says refresh/regenerate index → run a full pass, update **Generated** metadata on `docs/index.md`.
- Any edit that touches indexed concerns → patch the smallest set of docs that stay truthful.

## When not to use

- Pure typo/format-only changes with no semantic impact → index optional.
- Secrets or credentials → never document values; point to secret manager / env var **names** only.

## Quick audit

When a repo already has `docs/index.md`, run this first and again before finishing index work:

**Tool routing**

- macOS / Linux / WSL / Git Bash: use Bash.
- Native Windows / PowerShell-only shells: use PowerShell.
- Do **not** require Python for index auditing.

macOS / Linux:

```bash
bash <refs-dir>/scripts/audit_repo_index.sh <repo-root>
```

Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File <refs-dir>\scripts\audit_repo_index.ps1 <repo-root>
```

PowerShell 7+:

```powershell
pwsh -File <refs-dir>\scripts\audit_repo_index.ps1 <repo-root>
```

Resolve `<refs-dir>` to the absolute path of sibling directory `indexing-codebase-repos-refs` next to this skill. Use the output as a quality gate, not as a substitute for reading the docs. Fix **FAIL** items before claiming the index is current. Treat **WARN** items as review prompts: either link/update the doc, intentionally exclude generated/archive material, or record why no change is needed.

## Required layout (per repo)

All of the following **must exist** (split across files as below). See [../indexing-codebase-repos-refs/reference.md](../indexing-codebase-repos-refs/reference.md) for section checklists and [../indexing-codebase-repos-refs/templates/](../indexing-codebase-repos-refs/templates/) for copy-paste skeletons.

| Path | Purpose |
|------|---------|
| `docs/index.md` | Hub: purpose & boundaries, **Generated** block (UTC time + `git rev-parse HEAD`), links to every other page, short orientation |
| `docs/entrypoints.md` | Binaries, HTTP/gRPC servers, workers, cron, CLI, containers |
| `docs/layers.md` | Package/module layers, dependency direction, anti-patterns avoided |
| `docs/domains/*.md` | One file per bounded context: model, use cases, key types/paths, invariants |
| `docs/integrations.md` | External systems, clients, queues, webhooks, idempotency/timeouts |
| `docs/config-and-secrets.md` | Env vars, config files, feature flags; secret **names** and rotation notes only |
| `docs/observability.md` | Logs, metrics, traces, alerts, dashboards, SLOs if any |
| `docs/deployment-and-infra.md` | Docker, Helm/Kustomize, **values per env**, Terraform touchpoints, rollout notes |
| `docs/ownership.md` | Team, channels, on-call, escalation |
| `docs/where-to-change.md` | Tables: feature / bug class → package or path → how to verify |

**Domain files:** Name files by domain (`docs/domains/payments.md`). If a domain is huge, split subpages and link from its domain hub section in `docs/index.md`.

**Deep dives and existing docs:** Link useful top-level docs such as `developer-guide.md`, ADRs, rollout plans, or feature specs from `docs/index.md` or the relevant domain page. If a doc is stale, fix it, archive it outside the index path, or clearly mark it obsolete. Exclude transient generated artifacts (`docs/review/`, temporary plans, rendered reports) from the hub unless they are deliberately part of the maintained map.

**Size:** Unbounded. Prefer **tables, bullet lists, and path pointers** over dumping large trees or full APIs.

## Tech cues (this workspace)

- **Go:** `cmd/`, `internal/`, `pkg/`; note `make` targets (`test`, `lint`, `test-db`, `build`, generation targets, migrations).
- **Go + gopls MCP:** if the repo has `go.mod`/`go.work` and gopls is available, run `go_workspace` once to confirm module visibility. Use `go_package_api` for public package shape, `go_search` for symbol discovery, `go_symbol_references` for callers/implementations, `go_file_context` for cross-file dependencies, and `go_diagnostics` for workspace health. Use results to validate paths and flows; do **not** copy full symbol inventories into docs.
- **Go services with NATS/S2S:** capture generated contract packages, stream/consumer registration, background job commands, idempotency keys, retry/DLQ behavior, and config modes.
- **Go services with sqlc/migrations:** map query dirs, generated dirs, migration paths, and exact regeneration command.
- **Python (FastAPI etc.):** apps/packages, `alembic`, pytest layout.
- **Terraform / K8s values:** in `deployment-and-infra.md`, map **env → values file/chart** and what each overrides; link paths, do not duplicate entire YAML.

## AGENTS.md linkage (required in each repo)

Add the block from [../indexing-codebase-repos-refs/templates/AGENTS_SNIPPET.md](../indexing-codebase-repos-refs/templates/AGENTS_SNIPPET.md) to repo-root **`AGENTS.md`** (merge with any existing “Build and test” section; adapt the service name in step 1 only). The snippet is aligned with service-local agent notes (e.g. `wallester-integration/AGENTS.md`) and **must**:

- Point to `docs/index.md` as the **first** navigation stop (“hub file open first”).
- Require agents to **read the hub end-to-end**, then open linked pages for the task **before** large refactors or code writes.
- State that **ripgrep / globs / semantic search alone** are not sufficient orientation when the index covers the area—search comes **after** the index situates domains and paths.
- For Go repos, state that gopls MCP is preferred for symbol/API/caller questions when available, using portable tool names such as `go_search` and `go_symbol_references` rather than local server identifiers.
- State that agents **must update** affected `docs/**/*.md` in the **same change** when behavior, boundaries, entrypoints, integrations, config, observability, deployment, or “where to change” guidance changes.
- Require a final docs/index relevance check after code changes: compare changed paths to `docs/where-to-change.md`, domain pages, and cross-cutting pages; patch docs when applicable.
- Point full-index refresh to this skill and to updating the **Generated** block (UTC + full `git rev-parse HEAD`) in `docs/index.md`.
- Include a **Humans** subsection (prefer index first; same co-update rules).

## Workflow

1. Read repo-local `AGENTS.md`, then `docs/index.md` end-to-end if present. Follow its links before broad code search.
2. Run the OS-specific audit script if the index exists; save failures/gaps as the punch list.
3. Inspect targeted repo areas: entrypoints, configs, CI, infra paths, migrations/sqlc, generated contracts, main packages, and tests. For Go repos with gopls available, run `go_workspace` once, then prefer gopls MCP (`go_search`, `go_symbol_references`, `go_package_api`, `go_file_context`, `go_diagnostics`) for symbol/API/caller questions after the index points you at the area; use `rg` for non-Go text, docs/config, path discovery, or when gopls is unavailable/empty.
4. Create or update hub + layered pages; add/adjust domain files. Preserve useful repo-specific deep dives and link them from the hub or relevant domain page.
5. Ensure `AGENTS.md` contains the snippet (or merge if already partially there).
6. For full refresh, reconcile every section in [../indexing-codebase-repos-refs/reference.md](../indexing-codebase-repos-refs/reference.md), then set **Generated** on `docs/index.md`: ISO UTC datetime and full git SHA (`git rev-parse HEAD`).
7. For normal feature/bug edits, update only affected docs. Do not bump **Generated** unless you intentionally refreshed/reconciled the index.
8. Re-run the OS-specific audit script and fix **FAIL** output before completion.

## Common mistakes

- Stale **Generated** block or missing git SHA after a claimed refresh.
- Domain logic described only in `index.md` instead of `docs/domains/*.md`.
- Useful top-level docs left unlinked, especially old developer guides or feature specs that agents might find through search and trust by accident.
- Documenting secret values or internal URLs that should stay in runbooks only.
- Vague “where to change” rows without verification commands or test entrypoints.

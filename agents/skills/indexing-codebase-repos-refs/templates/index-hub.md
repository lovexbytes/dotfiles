# docs/index.md — skeleton

Replace `…` and remove comments.

```markdown
# <Service or library name>

## Purpose

…

## In scope

- …

## Out of scope

- …

## Generated

- **UTC:** YYYY-MM-DDTHH:MM:SSZ
- **Git:** <full 40-char sha from `git rev-parse HEAD`>

## Quick facts

| | |
|--|--|
| Languages | … |
| Build / test | … (e.g. `make test`) |
| Primary entrypoints | See [entrypoints.md](entrypoints.md) |
| Go navigation (if Go) | If gopls MCP is available: use `go_workspace` once, then `go_search`, `go_package_api`, `go_symbol_references`, `go_file_context`, and `go_diagnostics` for symbol-level follow-up. Keep paths repo-relative. |

## Documentation map

| Document | Description |
|----------|-------------|
| [entrypoints.md](entrypoints.md) | Processes and how they start |
| [layers.md](layers.md) | Architecture layers and dependency rules |
| [integrations.md](integrations.md) | External systems and clients |
| [config-and-secrets.md](config-and-secrets.md) | Configuration and secret references |
| [observability.md](observability.md) | Logs, metrics, traces |
| [deployment-and-infra.md](deployment-and-infra.md) | K8s, Helm values per env, Terraform |
| [ownership.md](ownership.md) | Team and contacts |
| [where-to-change.md](where-to-change.md) | Task → path → verification |

## Deep dives and local guides

| Document | Description |
|----------|-------------|
| [developer-guide.md](developer-guide.md) | Local setup / debugging, if maintained |
| [<feature-or-rollout>.md](<feature-or-rollout>.md) | Repo-specific feature, ADR, or rollout detail |

## Domains

| Domain | Description |
|--------|-------------|
| [domains/<name>.md](domains/example.md) | … |

(Add one row per file under `docs/domains/`.)

## Related repositories

(Optional; for future global index.)

- … → `other-repo/docs/index.md`
```

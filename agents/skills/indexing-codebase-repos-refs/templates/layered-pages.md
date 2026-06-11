# Skeletons for cross-cutting docs (except index and domains)

Use one section per file; expand freely.

## entrypoints.md

```markdown
# Entrypoints

| Entry | Type | Path | Local run | Prod / image |
|-------|------|------|-----------|----------------|
| … | HTTP | `cmd/…` | … | … |
```

## layers.md

```markdown
# Layers

## Layer diagram (or ordered list)

…

## Dependency rules

- …

## Key packages per layer

| Layer | Packages |
|-------|----------|
| … | … |
```

## integrations.md

```markdown
# Integrations

| System | Direction | Client / adapter path | Notes |
|--------|-----------|------------------------|-------|
| … | outbound | `…` | timeouts, idempotency |
```

## config-and-secrets.md

```markdown
# Configuration and secrets

## Environment variables

| Variable | Required | Default | Meaning |
|----------|----------|---------|---------|
| … | … | … | … |

## Files

- …

## Secrets (references only)

- …
```

## observability.md

```markdown
# Observability

## Logging

…

## Metrics

…

## Tracing

…

## Dashboards / alerts

…
```

## deployment-and-infra.md

```markdown
# Deployment and infrastructure

## Container

- Dockerfile: `…`
- Image: …

## Kubernetes / Helm

| Environment | Values file / overlay | Namespace | Notes |
|-------------|------------------------|-------------|-------|
| … | `…` | … | … |

## Terraform

- Roots / modules: `…`

## Jobs (migrations, seeds)

- …
```

## ownership.md

```markdown
# Ownership

- **Team:** …
- **Channel / chat:** …
- **Issue tracker:** …
- **On-call / escalation:** …
```

## where-to-change.md

```markdown
# Where to change what

| Task / symptom | Start here | Navigation hint | Verify |
|----------------|------------|-----------------|--------|
| … | `path/…` | For Go, start with `go_search <symbol>` or `go_package_api <package>` if useful. | `make test`, `…_test.go`, … |
```

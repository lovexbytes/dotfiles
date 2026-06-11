# Agents repository

This repository contains Golang Engineering agent instructions, reusable skills, and MCP server configuration for working with Go services.

Target reader: engineer who has not used agent skills or MCP servers before.

## What You Get

- Skills for Go code review, Go implementation style, Go tests, env config, PostgreSQL, sqlc, repo indexing, Mermaid diagrams, and ADRs.
- Agent-wide instructions in `AGENTS.md` that tell the agent when to use each skill.
- Codex MCP config in `mcp/codex/config.toml` for `gopls`: semantic Go navigation and diagnostics.

MCP means Model Context Protocol. In this setup, an MCP server is a local helper process the agent can call as a tool. `gopls` gives the agent Go-aware navigation.

Command examples below use macOS/Linux shell syntax. Windows users can run them from Git Bash, WSL, or adapt them to PowerShell.

## Prerequisites

Install or verify these before setup:

```bash
git --version
make --version
go version
```

Required:

- Git, for cloning and updating this repository.
- `make`, for skill install targets.
- Go, for installing `gopls`.
- Codex, OpenCode, or another agent client that supports `SKILL.md` skill directories and MCP servers.

## Quick Start For Codex

1. Install Codex.

Use the method approved for your workstation.

2. Clone or copy this repository.

```bash
cd agents
```

3. Install skills into Codex.

```bash
make install-codex
```

This creates symlinks under `~/.codex/skills`, so future repository updates are reflected after agent restart.

4. Safely merge agent instructions.

Do not overwrite an existing `~/.codex/AGENTS.md` without checking it first. Back it up, then append or manually merge this repo's `AGENTS.md`.

```bash
mkdir -p ~/.codex
touch ~/.codex/AGENTS.md
cp ~/.codex/AGENTS.md ~/.codex/AGENTS.md.backup-$(date +%Y%m%d-%H%M%S)
cat AGENTS.md >> ~/.codex/AGENTS.md
```

If `~/.codex/AGENTS.md` already contains an older copy of these rules, replace that block instead of appending duplicates.

5. Install `gopls`.

```bash
go install golang.org/x/tools/gopls@latest
```

Find the installed binary path:

```bash
command -v gopls || echo "$(go env GOPATH)/bin/gopls"
```

6. Configure the `gopls` MCP server.

Open `mcp/codex/config.toml` and copy its content into `~/.codex/config.toml`. If `~/.codex/config.toml` already exists, merge only the `[mcp_servers.gopls]` section.

Fill this placeholder:

- `mcp_servers.gopls.command`: absolute path to the `gopls` binary, for example `/Users/alex/go/bin/gopls`.

Example:

```toml
[mcp_servers.gopls]
command = "/Users/alex/go/bin/gopls"
args = ["mcp"]
type = "stdio"
enabled = true
startup_timeout_sec = 30
```

7. Restart the agent client.

Skills and MCP servers are loaded on startup. Restart is required after installing skills, changing `AGENTS.md`, or changing config.

8. Verify setup.

Ask the agent in any Go repository:

```text
List available skills.
Use gopls to summarize this Go workspace.
Review my uncommitted changes against main.
```

Expected:

- Skills are visible to the agent.
- `gopls` tools are available and can inspect Go packages.
- Local review can inspect tracked uncommitted changes.

## Other Agent Clients

Use this mapping when not using Codex:

| Client | Skills install target | Instructions file | MCP config |
|------|------|------|------|
| Codex | `make install-codex` -> `~/.codex/skills` | `~/.codex/AGENTS.md` | `~/.codex/config.toml` |
| Agent clients using `~/.agents` | `make install-agents` -> `~/.agents/skills/my-skill` | client-specific | client-specific |

For OpenCode, copy or symlink the `skills/*` directories that contain `SKILL.md` into `~/.config/opencode/skills` or `.opencode/skills` in a project. Merge `AGENTS.md` into the applicable OpenCode rules file.

For other clients, copy the `skills/*` directories that contain `SKILL.md` into that client's skill root and merge `AGENTS.md` into its instruction file. MCP syntax may differ; reuse the same command and args for `gopls`.

## What Is A Skill?

A skill is a directory with a `SKILL.md` file. The agent reads it when a task matches the skill description or when you invoke it manually.

You can use skills in two ways:

- Natural prompt: `Review my uncommitted Go changes against main.`
- Explicit invocation: `$go-review main`

`AGENTS.md` contains automatic routing rules. For example, Go tests trigger `go-tests`, env config work triggers `go-env-cfg`, and local uncommitted reviews trigger `go-review`.

## Skills Catalog

| Skill | Source path | Use when |
|------|-------------|----------|
| `db-postgresql` | `skills/db-postgresql` | Inspect or change PostgreSQL schema/data, migrations, indexes, enums, backfills, or migration SQL files. |
| `db-sqlc` | `skills/db-sqlc` | Change sqlc queries, regenerate sqlc output, or add a sqlc-backed repository/module. |
| `go-env-cfg` | `skills/go-env-cfg` | Create, edit, or review Go env config structs, `mapstructure` tags, viper, or servkit config loading. |
| `go-review` | `skills/go-review` | Review local uncommitted changes against a target branch. |
| `go-review-branch` | `skills/go-review-branch` | Review committed current-branch changes against a target branch. |
| `go-style` | `skills/go-style` | Create, modify, review, or refactor Go production code. |
| `go-tests` | `skills/go-tests` | Create, modify, review, debug, or choose strategy for Go tests. |
| `indexing-codebase-repos` | `skills/indexing-codebase-repos` | Build, refresh, audit, or extend repo navigation indexes under `docs/`. |
| `mermaid-diagrams` | `skills/mermaid-diagrams` | Write Mermaid diagrams when explicitly requested. |
| `write-adr` | `skills/write-adr` | Draft or update Architecture Decision Records. |

Support modules installed alongside skills:

- `skills/indexing-codebase-repos-refs`
- `skills/go-review-refs`

## Daily Usage Examples

### Go Code Work

```text
Use go-style and add validation to the payout status mapper.
```

```text
Use go-env-cfg and check whether this new config field maps to PAYOUT_RETRY_LIMIT.
```

### Go Tests

```text
Use go-tests and add coverage for this use case failure path.
```

```text
Use go-tests and explain which test shape fits this package.
```

### PostgreSQL And sqlc

```text
Use db-postgresql and inspect the local schema for payout tables.
```

```text
Use db-sqlc and add a query for listing payouts by status.
```

When both schema and sqlc query output change, use both:

```text
Use db-postgresql and db-sqlc to add a migration and regenerate sqlc code.
```

### Local Review

```text
$go-review main
$go-review main --only tests,performance,observability
$go-review main --only deps-supply-chain,sql-data-access,domain-invariants
```

### Branch Review

```text
$go-review-branch main
$go-review-branch main --only correctness,transactions,compatibility
$go-review-branch main --only deps-supply-chain,sql-data-access,domain-invariants
```

### Repo Index

```text
$indexing-codebase-repos create docs index for this repo
$indexing-codebase-repos refresh docs/index.md and linked docs
$indexing-codebase-repos update affected docs for this change
```

Use this when a repo needs or already has a maintained navigation map under `docs/`. The hub is `docs/index.md`; linked pages cover entrypoints, layers, domains, integrations, config/secrets, observability, deployment, ownership, and where-to-change guidance.

### Mermaid Diagrams

```text
$mermaid-diagrams draw a sequence diagram for payout retry processing
```

### ADRs

```text
$write-adr draft an ADR for using sqlc for payment queries
$write-adr create a decision record for replacing polling with events
$write-adr update the ADR for service-to-service HTTP contracts
$write-adr write an ADR for the new payout retry flow with a sequence diagram
```

## Review Output

Multi-agent review runs write to:

- `docs/review/<timestamp>_<source>/reports/*.json`
- `docs/review/<timestamp>_<source>/final-report.md`

Verdict rules:

- Critical findings present -> `REJECT`
- No critical and at least one major -> `REQUEST CHANGES`
- Only minor or none -> `LGTM`

Guidance:

- Share `final-report.md` with reviewers when useful.
- Treat `requires_verification: true` findings as manual follow-up items.
- Commit review reports only when the team wants an audit trail. Otherwise keep them local or delete them after use.

## Update

```bash
cd agents
git pull --ff-only
make install-codex
```

Then restart Codex. Symlink installs usually only need repository update plus restart, but running `make install-codex` verifies the expected skill links.

For `~/.agents` clients:

```bash
make install-agents
```

## Uninstall

Remove installed symlinks:

```bash
for skill in $(make list-skills); do
  rm -f "$HOME/.codex/skills/$skill"
done
```

Then remove or edit the copied block in `~/.codex/AGENTS.md` and remove the MCP section from `~/.codex/config.toml`.

## Troubleshooting

### Skills Do Not Appear

Check installed links:

```bash
make list-skills
ls -la ~/.codex/skills
```

Then restart Codex. If a target exists and install fails with `refusing to replace non-symlink install target`, move that existing directory aside and rerun the install target.

### `gopls` MCP Does Not Start

Check the binary path in `~/.codex/config.toml`:

```bash
command -v gopls
gopls version
```

Use an absolute path in `mcp_servers.gopls.command`. If `command -v gopls` is empty, reinstall:

```bash
go install golang.org/x/tools/gopls@latest
```

### Local Review Finds No Files

Verify that you have tracked uncommitted changes relative to the target branch:

```bash
git status --short
git diff main --stat
```

The review skill focuses on tracked files. Add new files to the index first if you want them included.

### Agent Ignores Skill Routing

Verify `AGENTS.md` content is present in the agent's instruction file and restart the agent. You can also invoke the skill explicitly with `$<skill-name>`.

## Security Notes

- Never commit local agent config files that contain secrets.
- Do not paste DB passwords or production secrets into prompts.

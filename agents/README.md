# Agent Configuration

Personal agent instructions, reusable skills, and MCP configuration for OpenCode and Hermes.

## Install

List skills:

```bash
make list-skills
```

Install all skills and shared instructions for OpenCode:

```bash
make install-opencode
```

Install all skills and shared instructions for Hermes:

```bash
make install-hermes
```

Install both:

```bash
make install
```

The macOS setup script calls these targets through its OpenCode and Hermes configuration steps.

The installer refuses to replace a real directory or file at an install target. Move that target manually before a retry. Existing symlinks are updated.

## Install Targets

| Client | Skills | Shared instructions |
|---|---|---|
| OpenCode | `~/.config/opencode/skills/<skill>` | `~/.config/opencode/AGENTS.md` |
| Hermes default profile | `~/.hermes/skills/<skill>` | `~/.hermes/SOUL.md` |
| Hermes `assistant` profile | `~/.hermes/profiles/assistant/skills/<skill>` | `~/.hermes/profiles/assistant/SOUL.md` |

## Skills

| Skill | Use when |
|---|---|
| `db-postgresql` | Inspect or change PostgreSQL schema, data, migrations, indexes, enums, or backfills. |
| `db-sqlc` | Change sqlc queries, regenerate output, or add a sqlc-backed repository. |
| `go-env-cfg` | Create or review Go environment configuration. |
| `go-style` | Create, modify, review, or refactor Go production code. |
| `go-tests` | Create, modify, review, or debug Go tests. |
| `review-local` | Review the current working tree against a target branch. |
| `review-branch` | Review committed current-branch changes against a target branch. |
| `grill-me` | Test a plan or design through structured questions. |
| `indexing-codebase-repos` | Build or update repository navigation documentation. |
| `mermaid-diagrams` | Write Mermaid diagrams when requested. |
| `write-adr` | Draft or update an Architecture Decision Record. |

Support modules do not contain `SKILL.md`. Entry skills reach them through relative links:

- `skills/review-refs`
- `skills/indexing-codebase-repos-refs`

## Review

The review stack supports:

- Go
- TypeScript and JavaScript
- Frontend source
- Dependency and lock files
- SQL and service contracts
- Build, CI, and deployment files

Examples:

```text
$review-local main
$review-local main --only typescript,web-accessibility
$review-branch main
$review-branch main --only correctness,transactions,compatibility
```

The review uses local Git only. It does not fetch merge requests or workplace tickets.

See `docs/review.md` for the workflow, routing, artifacts, and verdict rules.

## gopls MCP

The macOS installer installs the Homebrew `gopls` formula when Hermes or OpenCode is selected. For manual setup:

```bash
brew install gopls
command -v gopls
gopls version
```

Both clients start `gopls mcp` from their native configuration. Hermes stores it under `mcp_servers.gopls`. OpenCode stores it under `mcp.gopls`.

Restart the client after skill, instruction, or MCP changes.

## Verification

```bash
make list-skills
PYTHONDONTWRITEBYTECODE=1 python3 skills/review-refs/bin/test_review_tools.py
```

Use an isolated home to check install links without changing live configuration:

```bash
tmp="$(mktemp -d)"
make INSTALL_HOME="$tmp" install
find "$tmp" -type l -print
```

## Safety

- Never commit credentials or private agent configuration.
- Keep machine-specific paths out of shared configuration.
- Keep generated files generated. Change their source and regenerate them.
- Do not commit review reports unless they provide a useful audit record.

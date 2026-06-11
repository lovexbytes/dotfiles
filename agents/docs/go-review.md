# Go Review

## Overview

Go Review is a set of agent skills that automate code review for Go code. The review skills inspect local repository diffs and run specialized review agents for correctness, concurrency, style, tests, consistency, transactions, performance, security, observability, compatibility, distributed operations, dependencies, SQL access, and domain invariants.

Phase 1 creates shared review context (`review-context.json`) and prefetched file snapshots, then a conservative router skips only categories whose domain is provably not touched. Active agents run in two waves. All results, including router-skip reports, are merged, deduplicated, and rendered into a unified report with a verdict.

## Commands

| Command | What it reviews | Usage |
|-------|----------------|-------|
| `go-review` | Local uncommitted changes relative to target | `<target_branch> [--only agent1,agent2,...] [context]` |
| `go-review-branch` | Commits on the current branch relative to target | `<target_branch> [--only agent1,agent2,...] [context]` |

## Architecture

```text
User request
    |
    +--- local uncommitted changes ---> go-review/SKILL.md
    |
    +--- committed branch changes ----> go-review-branch/SKILL.md
                                        |
                                        v
                                  workflow.md
                                        |
                       +----------------+----------------+
                       |                                 |
                 tmp_dir artifacts                 output_dir report
```

Both skills use the shared contracts under `skills/go-review-refs/`.

## Skills

### go-review — Local Uncommitted

Reviews tracked staged and unstaged changes in the working tree against a target branch.

```text
$go-review main
$go-review main --only concurrency,security
$go-review main --only deps-supply-chain,sql-data-access,domain-invariants
```

Phase 1 uses local git commands such as:

```bash
git rev-parse --show-toplevel
git diff <target_branch> -- '*.go'
git diff --name-only <target_branch> -- <contract/deployment/dependency patterns>
```

### go-review-branch — Branch Commits

Reviews committed changes on the current branch against a target branch.

```text
$go-review-branch main
$go-review-branch main --only correctness,transactions,compatibility
$go-review-branch main --only deps-supply-chain,sql-data-access,domain-invariants
```

Phase 1 uses local git commands such as:

```bash
git diff <target_branch>..HEAD -- '*.go'
git diff --name-only <target_branch>..HEAD -- <contract/deployment/dependency patterns>
```

## Review Artifacts

Working data goes to `tmp_dir` under `/tmp/go-review/...`, which is ephemeral. The `output_dir` under `docs/review/...` is created for persistent results only.

Examples:

```text
/tmp/go-review/2026-04-03T14-30_local-feat/
/tmp/go-review/2026-04-03T14-30_branch-feat/
```

Each run creates:

- `tmp_dir/metadata.json`
- `tmp_dir/review-context.json`
- `tmp_dir/diffs/`
- `tmp_dir/files/`
- `tmp_dir/contract-files.txt`
- `output_dir/reports/*.json`
- `output_dir/final-report.md`

## File Filtering

Go file filtering applies to both skills: `.go` files, excluding `vendor/`, `*_mock.go`, `*.pb.go`, `*_generated.go`, `testdata/`, `*.gen.go`. Every matching `.go` change gets a per-file diff under `tmp_dir/diffs/`.

Non-Go review files go to `tmp_dir/contract-files.txt` for dependency, contract, deployment, and tooling review. This intentionally includes workflow/configuration files because those changes can affect build, test, release, or deployment behavior.

Full Go file bodies are prefetched into `tmp_dir/files/` when available in the local working tree.

## Agent Categories

| Agent | Focus |
|------|-------|
| `correctness` | Functional bugs, edge cases, broken assumptions |
| `concurrency` | Goroutines, locks, channels, atomics, races |
| `conventions` | Repository conventions and maintainability |
| `style` | Go style and readability |
| `tests` | Coverage quality and missing test cases |
| `consistency` | Cross-file and cross-layer consistency |
| `transactions` | Transaction boundaries and rollback behavior |
| `performance` | Inefficient algorithms, allocations, queries, hot paths |
| `security` | Injection, authorization, secrets, unsafe input handling |
| `observability` | Logs, metrics, traces, alertability |
| `compatibility` | API, config, schema, and mixed-version compatibility |
| `distributed-operations` | Idempotency, retries, queues, ordering, external effects |
| `deps-supply-chain` | Dependencies, generated code, toolchain risk |
| `sql-data-access` | SQL queries, migrations, indexes, persistence logic |
| `domain-invariants` | Business rules and state-machine invariants |

## Output Contract

Each agent writes a JSON report that follows `go-review-refs/output-contract.md`. The final report merges those results, deduplicates overlapping findings, validates scope, and renders a verdict.

Verdict rules:

- Critical findings present -> `REJECT`
- No critical and at least one major -> `REQUEST CHANGES`
- Only minor or none -> `LGTM`

## Context Rules

Each agent has its own trigger rules in `go-review-refs/context-rules/<agent>.md`. A trigger is a pattern in the diff that tells the agent to load additional files for deeper analysis.

Loading algorithm:

1. Agent detects a trigger in the diff.
2. Agent reads the relevant local repository files directly.
3. For related Go symbols/APIs/callers, prefer gopls MCP when local workspace context is available; for paths, non-Go text, or unavailable gopls, use local file search.

## Error Handling

- **Target branch not found**: review stops with an error message.
- **Detached HEAD**: local review stops and asks for a branch checkout.
- **No reviewable files**: review stops with an appropriate no-files message.
- **Sub-agent failure**: log the failure and continue with remaining agents.

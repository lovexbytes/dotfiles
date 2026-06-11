---
name: go-review-branch
description: Use when reviewing committed Go, dependency, SQL, or service-contract changes against a target branch
---

# Go Review (Branch)

All commits on current branch vs target; fifteen agent categories on diffs and sources; conservative router skips only not-applicable categories; one merged report.

## Usage

```
<target_branch> [--only agent1,agent2,...] [free text context]
```

Examples:
```
main
main --only concurrency,security
develop --only correctness,transactions,compatibility
develop --only distributed-operations,transactions,observability
develop --only deps-supply-chain,sql-data-access,domain-invariants
main
Рефакторинг слоя репозиториев, переход на sqlc.
```

Available agents: `correctness`, `concurrency`, `conventions`, `style`, `tests`, `consistency`, `transactions`, `performance`, `security`, `observability`, `compatibility`, `distributed-operations`, `deps-supply-chain`, `sql-data-access`, `domain-invariants`

## Review Discipline

- **High-confidence findings only.** Confidence below ~70% → `open_questions`, not `findings`.
- **Deploy-time / rollback-time / mixed-version lens** applies on anything touching schema, contract, cache format, persisted state, or public API.
- **Data-flow summary before checklist.** Each agent writes a brief internal summary — entrypoint → state transitions → commits → publishes → external effects — and uses it to detect mismatches between code intent and system guarantees.
- **Final scope validation.** After agent reports are merged, classify every finding as `in_scope` or `out_of_scope`. Out-of-scope findings stay in the report under their own section and do not affect verdict.

## Parse Input

1. `target_branch` = first token (required). Verify: `git rev-parse --verify <target_branch>`. Missing branch → stop: "Branch `<target_branch>` not found."

2. `source_branch`: `git branch --show-current`. Detached HEAD → stop: "Cannot review from detached HEAD. Please check out a branch."

3. `--only` (optional): split on commas; each token must be a known agent; on unknown name, stop and list valid agents; if omitted, all fifteen agents are selected before conservative routing.

4. `additional_context`: remaining text after branch name and flags.

5. Paths:
   - `tmp_dir` = `/tmp/go-review/<YYYY-MM-DDTHH-MM>_branch-<source_branch>/`
   - `output_dir` = `docs/review/<YYYY-MM-DDTHH-MM>_branch-<source_branch>/`
   - Timestamp: current time, 24h clock, dashes not colons in time portion

## Execute

Run `workflow.md` (same directory as this file) with:
- `{{target_branch}}`
- `{{source_branch}}`
- `{{selected_agents}}`
- `{{additional_context}}`
- `{{tmp_dir}}`
- `{{output_dir}}`

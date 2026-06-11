---
name: go-review
description: Use when reviewing uncommitted local Go, dependency, SQL, or service-contract changes before commit
---

# Go Review (Local Uncommitted)

Uncommitted changes (staged + unstaged, tracked) vs target branch; fifteen agent categories on diffs and sources; conservative router skips only not-applicable categories; one merged report.

## Usage

```
<target_branch> [--only agent1,agent2,...] [free text context]
```

Examples:
```
main
main --only concurrency,security
develop --only correctness,transactions,compatibility
main --only distributed-operations,transactions,observability
main --only deps-supply-chain,sql-data-access,domain-invariants
main
Добавляю валидацию email и проверку уникальности username.
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

3. Uncommitted reviewable files vs target include tracked `.go`, dependency, contract, and deployment/tooling files. Workflow decides final scope; if all reviewable diffs are empty, it stops with the workflow's no-files message.

4. `--only` (optional): split on commas; each token must be a known agent; on unknown name, stop and list valid agents; if omitted, all fifteen agents are selected before conservative routing.

5. `additional_context`: remaining text after branch name and flags.

6. Paths:
   - `tmp_dir` = `/tmp/go-review/<YYYY-MM-DDTHH-MM>_local-<source_branch>/`
   - `output_dir` = `docs/review/<YYYY-MM-DDTHH-MM>_local-<source_branch>/`
   - Timestamp: current time, 24h clock, dashes not colons in time portion

## Execute

Run `workflow.md` (same directory as this file) with:
- `{{target_branch}}`
- `{{source_branch}}`
- `{{selected_agents}}`
- `{{additional_context}}`
- `{{tmp_dir}}`
- `{{output_dir}}`

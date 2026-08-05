---
name: review-branch
description: Use when reviewing committed Go, TypeScript, web, dependency, SQL, or contract changes against a target branch
---

# Branch Review

Review committed changes on the current branch against a target branch. Materialize deterministic per-file diffs, route only applicable agents, and write one merged report.

## Usage

```
<target_branch> [--only agent1,agent2,...] [free text context]
```

Examples:
```
main
main --only concurrency,security
main --only typescript,web-accessibility
develop --only correctness,transactions,compatibility
main
Refactor the repository layer to use sqlc.
```

Available agents: `correctness`, `concurrency`, `conventions`, `style`, `tests`, `typescript`, `consistency`, `transactions`, `performance`, `security`, `observability`, `compatibility`, `distributed-operations`, `deps-supply-chain`, `sql-data-access`, `domain-invariants`, `web-ui-architecture`, `web-forms-validation`, `web-accessibility`, `web-frontend-performance`

## Review Discipline

- **High-confidence findings only.** Confidence below ~70% → `open_questions`, not `findings`.
- **Deploy-time / rollback-time / mixed-version lens** applies on anything touching schema, contract, cache format, persisted state, or public API.
- **Data-flow summary before checklist.** Each agent writes a brief internal summary — entrypoint → state transitions → commits → publishes → external effects — and uses it to detect mismatches between code intent and system guarantees.
- **Final scope validation.** After agent reports are merged, classify every finding as `in_scope` or `out_of_scope`. Out-of-scope findings stay in the report under their own section and do not affect verdict.

## Parse Input

1. `target_branch` = first token (required). Verify: `git rev-parse --verify --end-of-options "<target_branch>^{commit}"`. Missing branch → stop: "Branch `<target_branch>` not found."

2. `source_branch`: `git branch --show-current`. Detached HEAD → stop: "Cannot review from detached HEAD. Please check out a branch."

3. `--only` (optional): split on commas; each token must be a known agent. Stop and list valid agents for an unknown name. If omitted, select all agents before routing.

4. `additional_context`: remaining text after branch name and flags.

5. Paths:
   - `tmp_dir` = `/tmp/review/<YYYY-MM-DDTHH-MM>_branch-<source_branch>/`
   - `output_dir` = `docs/review/<YYYY-MM-DDTHH-MM>_branch-<source_branch>/`
   - Timestamp: current time, 24h clock, dashes not colons in time portion

## Execute

Resolve the directory that contains this `SKILL.md` as `{{skill_dir}}`. Run `review-refs/workflow.md` with:
- `{{scope}}` = `branch`
- `{{target_branch}}`
- `{{source_branch}}`
- `{{diff_spec}}` = `{{target_branch}}...HEAD`
- `{{selected_agents}}`
- `{{additional_context}}`
- `{{tmp_dir}}`
- `{{output_dir}}`
- `{{skill_dir}}`

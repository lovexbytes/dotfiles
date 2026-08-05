# Review Workflow

Use this workflow for local working-tree and committed branch reviews.

## Inputs

- `{{scope}}`: `local` or `branch`
- `{{target_branch}}`: comparison branch
- `{{source_branch}}`: current branch
- `{{diff_spec}}`: `{{target_branch}}` for local scope or `{{target_branch}}...HEAD` for branch scope
- `{{selected_agents}}`: all agents or the validated `--only` list
- `{{additional_context}}`: optional user context
- `{{tmp_dir}}`: temporary artifact directory
- `{{output_dir}}`: persistent report directory
- `{{skill_dir}}`: directory that contains the active `SKILL.md`

## Agents

Wave 1:

- `correctness`
- `concurrency`
- `conventions`
- `style`
- `performance`
- `security`
- `tests`
- `typescript`
- `observability`
- `deps-supply-chain`
- `sql-data-access`
- `web-ui-architecture`
- `web-forms-validation`
- `web-accessibility`
- `web-frontend-performance`

Wave 2:

- `consistency`
- `transactions`
- `compatibility`
- `distributed-operations`
- `domain-invariants`

Only launch agents whose `agent_plan` decision is `run`.

## Phase 1: Materialize and Route

### 1. Create directories and resolve the repository

```bash
mkdir -p "{{tmp_dir}}" "{{output_dir}}/reports"
git rev-parse --show-toplevel
git config user.name
git log "{{target_branch}}..HEAD" --format='%h %s' --no-merges
```

Save the repository root, author, and optional branch commit log.

### 2. Capture the complete Git diff

Use RTK when it is installed. RTK must proxy the raw Git output. Do not use summarized RTK output as review input.

```bash
if command -v rtk >/dev/null 2>&1; then
  rtk proxy git diff "{{diff_spec}}" -- > "{{tmp_dir}}/full.diff"
else
  git diff "{{diff_spec}}" -- > "{{tmp_dir}}/full.diff"
fi
```

### 3. Materialize one diff per file

```bash
python3 "{{skill_dir}}/review-refs/bin/materialize-diffs.py" \
  --unified "{{tmp_dir}}/full.diff" \
  --out "{{tmp_dir}}"
```

A non-empty input that cannot be parsed is an error. Stop instead of running agents without diffs.

### 4. Write metadata

Write `{{tmp_dir}}/metadata.json`:

```json
{
  "title": "{{source_branch}} vs {{target_branch}}",
  "author": "<git config user.name>",
  "scope": "{{scope}}",
  "source_branch": "{{source_branch}}",
  "target_branch": "{{target_branch}}",
  "description": "<branch commit log when scope is branch>",
  "additional_context": "{{additional_context}}",
  "fetched_at": "<current ISO timestamp>"
}
```

### 5. Build the review context

Pass the selected list only when `--only` was supplied.

```bash
python3 "{{skill_dir}}/review-refs/bin/build-review-context.py" \
  --tmp-dir "{{tmp_dir}}" \
  --scope "{{scope}}" \
  --reports-dir "{{output_dir}}/reports" \
  [--selected "agent1,agent2"]
```

The router writes:

- `review-context.json`
- `contract-files.txt`
- valid empty reports for skipped selected agents

Stop when both `changed_source_files` and `contract_files` are empty. Report that no reviewable changes were found.

## Phase 2: Wave 1

Launch one bounded review task for each active Wave 1 agent. Run independent tasks in parallel within the available agent limit.

Construct each prompt from:

```text
You are the {agent_name} review agent.

{contents of review-refs/agents/{agent_name}.md}

Input:
- metadata: {{tmp_dir}}/metadata.json
- review context: {{tmp_dir}}/review-context.json
- per-file diffs: {{tmp_dir}}/diffs/
- repository root: {{repo_root}}
- output report: {{output_dir}}/reports/{agent_name}.json

Start with agent_plan.{agent_name}.files.
Read changed files from the repository only when the diff is not enough.
For deleted files, use the diff and `git show {{target_branch}}:<old_path>` when full prior context is necessary.
For Go symbol, API, and caller questions, use gopls MCP tools when available. Use file search for non-Go text or when gopls fails, and state the fallback if it affects confidence.
Read only the extra context required by review-refs/context-rules/{agent_name}.md.

Author context:
{{additional_context}}

Return only JSON that follows review-refs/output-contract.md and review-refs/agent-output-schema.json.
```

Wait for every Wave 1 task. Confirm that every expected report exists and parses as JSON. Retry one malformed or missing report once with the validation error. After a second failure, write a valid empty report with the failure in `open_questions` and continue.

## Phase 3: Wave 2

Launch active Wave 2 agents with the same prompt and validation rules. Include completed Wave 1 reports as optional evidence when the Wave 2 context rules require them.

Wait for all Wave 2 tasks.

## Phase 4: Merge and Validate

1. Read every selected-agent report.
2. Validate the required fields and agent-specific ID prefixes.
3. Merge findings and positive notes.
4. Deduplicate only when file, line, mechanism, and fix direction match.
5. Keep the higher severity. Keep the clearer explanation. Record the other agent as supporting evidence.
6. Apply `review-refs/scope-validation.md` to every finding.
7. Mark each finding `in_scope` or `out_of_scope` with a reason.
8. Exclude out-of-scope findings from the verdict.
9. Merge and deduplicate `open_questions`. Keep at most ten.
10. Save `{{output_dir}}/merged.json`.

Verdict:

- Any in-scope critical finding: `REJECT`
- Otherwise, any in-scope major finding: `REQUEST CHANGES`
- Otherwise: `LGTM`

## Phase 5: Report

Render `{{output_dir}}/review.md` with `review-refs/report-format.md`.

Every finding must have either:

- non-empty before and after snippets; or
- `code_snippet_unavailable: true` and a concrete `code_absence_note`

Report:

```text
Review complete: {{output_dir}}/review.md
  Verdict: <verdict>
  In scope: <critical> critical, <major> major, <minor> minor
  Out of scope: <count>
  Open questions: <count>
```

---
name: go-review-branch-workflow
description: 5-phase orchestration workflow for local branch Go code review
---

# Go Review Workflow — Branch

## Prerequisites

**From SKILL.md (before Phase 1):**
- `{{target_branch}}` — branch to compare against (e.g., `main`)
- `{{source_branch}}` — current branch name
- `{{selected_agents}}` — list of agents to run (default: all 15)
- `{{additional_context}}` — free text context from user (may be empty)
- `{{tmp_dir}}` — path to temporary working directory (e.g., `/tmp/go-review/2026-04-03T14-30_branch-feature-xyz/`)
- `{{output_dir}}` — path to persistent output directory (e.g., `docs/review/2026-04-03T14-30_branch-feature-xyz/`)

**Set in Phase 1.2 (then substitute into Phase 2–3 agent prompts):**
- `{{repo_root}}` — absolute path from `git rev-parse --show-toplevel` (trimmed); used in File Access paths below

## Constants

```
WAVE_1_AGENTS = [correctness, concurrency, conventions, style, performance, security, tests, observability, deps-supply-chain, sql-data-access]
WAVE_2_AGENTS = [consistency, transactions, compatibility, distributed-operations, domain-invariants]

AGENT_PREFIXES = {
  correctness: "CORR",
  concurrency: "CONC",
  conventions: "CONV",
  style: "STYL",
  performance: "PERF",
  security: "SEC",
  tests: "TEST",
  "deps-supply-chain": "DEPS",
  "sql-data-access": "SQL",
  consistency: "CONS",
  transactions: "TXN",
  observability: "OBSV",
  compatibility: "COMPAT",
  "distributed-operations": "DIST",
  "domain-invariants": "DOM"
}

EXCLUDED_FILE_PATTERNS = ["^vendor/", "_mock\\.go$", "\\.pb\\.go$", "_generated\\.go$", "^testdata/", "\\.gen\\.go$"]
REVIEW_CONTEXT_CONTRACT = "go-review-refs/review-context.md"
OUTPUT_CONTRACT = "go-review-refs/output-contract.md"
SCOPE_VALIDATION_CONTRACT = "go-review-refs/scope-validation.md"
```

---

## Phase 1: Fetch from Local Git

Goal: Generate diffs from local git and save to `{{tmp_dir}}`.

### Step 1.1 — Create directories

```bash
mkdir -p {{tmp_dir}}/diffs
mkdir -p {{tmp_dir}}/files
mkdir -p {{output_dir}}/reports
```

### Step 1.2 — Determine repo root

```bash
git rev-parse --show-toplevel
```

Use the printed path (trimmed, no trailing newline) as `{{repo_root}}` for all later steps and for substituting into Phase 2–3 agent prompts (`Read {{repo_root}}/...`).

### Step 1.3 — Get commit log for description

```bash
git log {{target_branch}}..HEAD --format="%h %s" --no-merges
```

Save output as `commit_log` for metadata.

### Step 1.4 — Get diffs

```bash
git diff {{target_branch}}..HEAD -- '*.go'
```

From the combined diff output:
- Split into per-file diffs
- Exclude files matching EXCLUDED_FILE_PATTERNS
- Save each file's diff to `{{tmp_dir}}/diffs/<path-with-dashes>.diff`
  (replace `/` with `-` in path)
- Track: file path, lines added, lines removed

Do not stop yet if no `.go` files are in the diff; dependency, contract, or deployment files below may still be reviewable.

**Contract/deployment/dependency manifest.** Also list non-Go contract, deployment, dependency, and tooling files that differ vs `{{target_branch}}` so any interested agent can iterate them:

```bash
git diff --name-only {{target_branch}}..HEAD -- \
  '*.proto' \
  '**/migrations/*.sql' 'cmd/migrations/*.sql' \
  '*.up.sql' '*.down.sql' \
  'go.mod' 'go.sum' 'go.work' 'go.work.sum' 'vendor/modules.txt' \
  'buf*.yaml' 'buf*.yml' 'sqlc*.yaml' 'sqlc*.yml' '.mockery.yaml' '.mockery.yml' \
  'Makefile' '.tool-versions' \
  'deploy/**/*.yaml' 'deploy/**/*.yml' \
  'helm/**/*.yaml' 'helm/**/*.yml' \
  'k8s/**/*.yaml' 'k8s/**/*.yml' \
  'kubernetes/**/*.yaml' 'kubernetes/**/*.yml' \
  'charts/**/*.yaml' 'charts/**/*.yml' \
  'manifests/**/*.yaml' 'manifests/**/*.yml' \
  'openapi*.yaml' 'openapi*.yml' 'swagger*.yaml' 'swagger*.yml' \
  'Dockerfile' 'Dockerfile.*' \
  '.gitlab-ci.yml' '.github/workflows/*.yml' '.github/workflows/*.yaml'
```

Write the resulting paths (one per line) to `{{tmp_dir}}/contract-files.txt`. Empty file is fine.

If no `.go` files are in the diff and `contract-files.txt` is empty, stop and report: "No Go, dependency, contract, or deployment files changed between `{{source_branch}}` and `{{target_branch}}`."

### Step 1.5 — Prefetch changed Go files

For every changed or added `.go` file that exists in the working tree after exclusions, copy the current file to `{{tmp_dir}}/files/<original path>` preserving directories.

```bash
mkdir -p "{{tmp_dir}}/files/<dir-of-path>"
cp "{{repo_root}}/<path>" "{{tmp_dir}}/files/<path>"
```

For deleted files, do not prefetch; the per-file diff is enough for most agents, and agents can use `git show {{target_branch}}:<old_path>` when they need the previous full file.

### Step 1.6 — Get author

```bash
git config user.name
```

### Step 1.7 — Write metadata.json

Save to `{{tmp_dir}}/metadata.json`:
```json
{
  "title": "Branch {{source_branch}} vs {{target_branch}}",
  "author": "<git config user.name>",
  "source_branch": "{{source_branch}}",
  "target_branch": "{{target_branch}}",
  "description": "<commit_log from step 1.3>",
  "url": "",
  "fetched_at": "<current ISO timestamp>",
  "existing_discussions": [],
  "additional_context": "{{additional_context}}"
}
```

### Step 1.8 — Build review-context.json and route agents

Load `go-review-refs/review-context.md`. Using the per-file diffs, prefetched paths, `contract-files.txt`, metadata, and `{{selected_agents}}`, write `{{tmp_dir}}/review-context.json`.

The artifact must include changed Go files, contract files, aggregate trigger hints, and `agent_plan` for every known agent with `decision` = `run`, `focused`, or `skip`; `reason`; and scoped `files`.

Routing rules:
- Apply only to agents in `{{selected_agents}}`.
- If confidence in a skip decision is low, choose `run`.
- Always preserve quality by using the safe skip conditions from `review-context.md`.
- For each skipped selected agent, write a valid JSON report to `{{output_dir}}/reports/{agent_name}.json`:

```json
{
  "agent": "{agent_name}",
  "files_checked": 0,
  "findings": [],
  "positive": ["Skipped by conservative router: <reason from review-context.json>"],
  "open_questions": []
}
```

Set `active_agents` to selected agents whose decision is `run` or `focused`.

### Step 1.9 — Report fetch results

Output to user:
```
Review: {{source_branch}} vs {{target_branch}}
  Author: <author>
  Files: <N> .go files (<lines_added>+ / <lines_removed>-), <M> non-Go review files
  Commits: <N>
  Agents: <active_agents> active, <N> skipped by conservative router
  Launching Wave 1...
```

---

## Phase 2: Wave 1

Goal: Wave 1 in parallel; each active agent reads shared review context first, then scoped diffs/full files; emits one JSON report.

### For each agent in `WAVE_1_AGENTS ∩ active_agents`:

**Parallel Agents:** send one message that starts every agent in this wave.

Each agent prompt is constructed as follows:

```
You are the {agent_name} review agent.

{contents of go-review-refs/agents/{agent_name}.md}

## Input

Metadata: {{tmp_dir}}/metadata.json
Review context: {{tmp_dir}}/review-context.json
Diffs: {{tmp_dir}}/diffs/
Output directory for your report: {{output_dir}}/reports/

## File Access

Prefetched full files are in {{tmp_dir}}/files/. Start with `agent_plan.{agent_name}.files` from review-context.json and read prefetched files first when `prefetched_path` is non-empty.
If a file you need is not prefetched, read it directly from the repository at: {{repo_root}}/<file_path>.
For deleted files, use the `.diff` text and run `git show {{target_branch}}:<old_path>` only when full pre-delete context is required.
For Go symbol/API/caller questions, prefer gopls MCP tools (`go_search`, `go_symbol_references`, `go_package_api`, `go_file_context`, `go_workspace`, `go_diagnostics`) against the local workspace when available.
Use Glob/Grep or `rg` for paths, non-Go text, docs/config, or when gopls returns empty/errors; note the fallback in your report if it affects confidence.
Non-Go contract/deployment/dependency files changed in this branch are listed in {{tmp_dir}}/contract-files.txt (one path per line, relative to {{repo_root}}). Use it if your checklist cares about `.proto`, SQL migrations, Helm/K8s manifests, OpenAPI, CI config, `go.mod`, `go.sum`, Dockerfiles, or codegen config.
For those non-Go files, read the current file from `{{repo_root}}/<path>` and, when the diff matters, use `git show {{target_branch}}:<path>` for the prior revision.

## Context Rules

{contents of go-review-refs/context-rules/{agent_name}.md}

## Task Context (provided by author)

{{additional_context}}

## Output Contract

{contents of go-review-refs/output-contract.md}

## Instructions

1. Read metadata.json for review context.
2. Read review-context.json and your `agent_plan.{agent_name}` entry before any broad search.
3. Read `.diff` files for every planned Go path. If your agent plan says `run` with an empty file list, read every `.diff` in diffs/.
4. For each planned Go diff, read the prefetched file first; if absent, read the full file via File Access when needed. For planned non-Go paths from `contract-files.txt`, read source and target revisions when the changed content matters.
5. **Pre-checklist data-flow summary.** Before running the checklist, write a brief internal summary: entrypoint → state transitions → commits → publishes → external effects. Use it to detect mismatches between code intent and actual system guarantees (metric semantics, delivery guarantees, atomicity, cache coherence).
6. Apply the **deploy-time / rollback-time / mixed-version** lens on anything touching schema, contract, cache format, persisted state, or public API — not just steady state.
7. Run checklist on every planned file and any extra file loaded by context rules.
8. When context-rules fire, load more files via File Access.
9. **Confidence discipline.** If confidence in a finding is below ~70%, move it to `open_questions`, not `findings`.
10. **Write** JSON with Write → `{{output_dir}}/reports/{agent_name}.json` (must exist on disk after you finish).
11. Return the same JSON to the orchestrator.
```

Block until every Wave 1 agent finishes, then Phase 3.

---

## Phase 3: Wave 2

Goal: Wave 2 in parallel; each active agent also consumes Wave 1 JSON and shared review context.

### For each agent in `WAVE_2_AGENTS ∩ active_agents`:

**Parallel Agent:** reuse the Phase 2 prompt shell; after `## Input` add:

```
## Wave 1 Findings

Earlier agents wrote JSON under `{{output_dir}}/reports/`. Read what you need first:
- Do not repeat a finding already there
- Use them to narrow scope (e.g., resource leak → transaction boundaries)

JSON files present:
{list of reports/*.json files that exist}
```

Block until every Wave 2 agent finishes, then Phase 4.

---

## Phase 4: Merge

Goal: Merge all agent JSON into one deduped finding list, then classify final scope before report rendering.

### Step 4.1 — Load all reports

Read every `{{output_dir}}/reports/*.json` file.
Skipped-by-router reports are valid reports with zero findings; preserve their positive note for Verification/Gaps, but do not count them as failed agents.

### Step 4.2 — Deduplicate

For each pair of findings from different agents:
- If `file` AND `line` match (same location):
  - Keep the finding from the more specialized agent:
    - concurrency > correctness (for race conditions)
    - transactions > correctness (for resource leaks in tx scope)
    - security > correctness (for injection issues)
    - consistency > conventions (for interface contract issues)
    - conventions > correctness (for error handling style — missing %w, error string format)
    - conventions > style (for naming / doc overlap — conventions owns API-facing convention)
    - correctness > style (for pointer-to-interface and similar foot-guns that are correctness-adjacent)
    - concurrency > performance (for lock contention — deadlock risk outweighs perf concern)
    - concurrency > correctness (for context cancellation leaks — goroutine lifecycle is root cause)
    - tests > correctness (for missing test coverage — tests agent is more specific about what's missing)
    - tests > conventions (for test quality — tests agent owns test patterns)
    - observability > correctness (for metric/log semantic bugs — observability owns metric lifecycle)
    - observability > conventions (for structured-logging/metric-naming patterns)
    - observability > performance (for retry/circuit-breaker visibility — observability owns operational signal)
    - security > observability (for PII/secret leakage — security wins on data-exposure)
    - compatibility > consistency (for cross-binary / rollout / public-API contract breaks)
    - compatibility > transactions (for persistent-state format or migration-rollout issues)
    - distributed-operations > transactions (for retry, replay, idempotency, inbox/outbox, compensation, and cross-boundary partial-failure issues)
    - transactions > distributed-operations (for pure local tx hygiene with no distributed failure semantics)
    - distributed-operations > performance (for retry storms, timeout-budget misuse, unsafe fan-out, or degraded-dependency behavior when the main issue is incorrect side effects or unsafe recovery)
    - performance > distributed-operations (for purely throughput, latency, or allocation issues)
    - distributed-operations > observability (when the runtime behavior is unsafe)
    - observability > distributed-operations (when the runtime behavior is acceptable but insufficiently visible)
    - compatibility > distributed-operations (for mixed-version, rollback, or public-contract breaks)
    - security > distributed-operations (for primary security failures even if they appear on retry or fallback paths)
    - concurrency > distributed-operations (for primary local race or deadlock issues)
    - deps-supply-chain > compatibility (for module, toolchain, codegen, build image, or CI dependency drift)
    - security > deps-supply-chain (for primary exploitable dependency or credential exposure)
    - sql-data-access > correctness (for query shape, scan/nullability, no-row, pagination, and sqlc contract issues)
    - sql-data-access > performance (for index/query-plan fit where correctness of access pattern is the root issue)
    - security > sql-data-access (for SQL injection or auth-sensitive query exposure)
    - compatibility > sql-data-access (for old/new binary schema compatibility and rollout safety)
    - domain-invariants > correctness (for business-rule failures even when the code-level symptom is a branch/guard bug)
    - domain-invariants > transactions (for balance/currency/state invariants; transactions still owns local tx hygiene)
    - domain-invariants > sql-data-access (for wrong business row selection or domain identity mismatch)
    - domain-invariants > distributed-operations (for duplicate/replay behavior whose primary impact is a broken business invariant)
  - If neither is more specialized, keep both (different perspectives are valuable)

#### Dedup Rules (Strip / Preserve)

- **Strip:** Duplicate finding on same file:line from lower-priority agent — remove the lower-priority one.
- **Preserve:** Keep both findings if they describe different failure modes on the same line, even from different agents.
- **Positive merge:** Deduplicate semantically similar positives; keep the more specific phrasing.
- **Open questions merge:** Union all; deduplicate by meaning; cap at 10 total.

### Step 4.3 — Final scope validation

Load `go-review-refs/scope-validation.md`. For every deduped finding, compare it against `{{tmp_dir}}/review-context.json`, the saved diffs, `contract-files.txt`, metadata, and any loaded file context that supports the finding.

Set:
- `scope_status = "in_scope"` when the issue is caused by, exposed by, or required to safely deploy this branch change.
- `scope_status = "out_of_scope"` when the issue is pre-existing or unrelated to the reviewed change.
- `scope_reason` to one concise sentence explaining the causal link or why the finding is independent from this branch change.

Do not delete out-of-scope findings. Preserve them for the report's **Out Of Scope Findings** section. Out-of-scope findings do not affect severity counts, key production risks, or verdict.

### Step 4.4 — Sort and group

Group findings:
1. Main findings: only `scope_status = "in_scope"`, first by severity (critical → major → minor), then agent category (in order: correctness, concurrency, conventions, style, tests, deps-supply-chain, sql-data-access, consistency, transactions, domain-invariants, distributed-operations, performance, security, observability, compatibility)
2. Out-of-scope findings: only `scope_status = "out_of_scope"`, first by severity, then agent category

### Step 4.5 — Compute statistics

```json
{
  "files_checked": "<union of files_checked across all agents>",
  "lines_added": "<from Phase 1>",
  "lines_removed": "<from Phase 1>",
  "critical_count": "<in-scope count>",
  "major_count": "<in-scope count>",
  "minor_count": "<in-scope count>",
  "out_of_scope_count": "<out-of-scope count>",
  "verdict": "<REJECT if in-scope critical > 0, REQUEST CHANGES if in-scope major > 0, LGTM otherwise>"
}
```

### Step 4.6 — Merge positive findings

Collect all `positive` arrays from all agents. Deduplicate semantically similar observations; keep the more specific phrasing. Keep as bullet list.

### Step 4.7 — Merge open questions

Collect all `open_questions` arrays from all agents. Deduplicate by meaning. Cap at 10 total. Prefix each with the agent name.

---

## Phase 5: Report

Goal: Render the final markdown report and present to user.

### Step 5.1 — Load template

Read `go-review-refs/report-format.md`.

### Step 5.2 — Render

Fill the template with:
- Metadata from `{{tmp_dir}}/metadata.json`
- **What This Change Does** — 2–5 sentences derived from the diff + commit log + data-flow summaries.
- **System And End-User Impact** — runtime / operators / end-users bullets; "no direct end-user impact" is acceptable when true.
- Statistics from Phase 4
- Grouped in-scope findings and grouped out-of-scope findings from Phase 4 (includes **observability**, **compatibility**, and **distributed-operations** sections)
- **Distributed Operations Review** — populate from in-scope `distributed-operations` agent findings. If only out-of-scope distributed concerns exist, point to **Out Of Scope Findings**. If `distributed-operations` was selected and completed with no in-scope findings → `No distributed-operations safety issues found.` If excluded by `--only` → `Distributed operations review was not run (--only excluded it).` If selected but missing/failed → `Distributed operations review did not complete; see Verification.`
- **Backward Compatibility Review** — populate from in-scope `compatibility` agent findings plus in-scope cross-binary concerns from `consistency`. If only out-of-scope compatibility concerns exist, point to **Out Of Scope Findings**. If `compatibility` was selected and completed with no in-scope findings and no matching in-scope `consistency` findings → `No backward compatibility issues found.` If excluded by `--only` → `Backward compatibility review was not run (--only excluded it).` If selected but missing/failed → `Backward compatibility review did not complete; see Verification.`
- Merged positive findings
- Key production risks (summarize in-scope critical + major findings impact)
- **Verification** — list commands actually run by the orchestrator (usually none on branch flow; state `Static review only; no commands executed by the orchestrator.` when so). List every `requires_verification: true` finding in "Could not verify". List `--only` exclusions and router-skipped selected agents under "Gaps".

**Report snippets (mandatory):** `go-review-refs/report-format.md` Orchestrator contract section. Per finding: `code_snippet_unavailable` true → **Code snippet:** not applicable + `code_absence_note` only (no fences; do not reconstruct past waiver). Else fenced Before/After from `code_before`/`code_after`; if missing, reconstruct from `{{tmp_dir}}/diffs/` + repo file at `file`/`line`. Never empty mode-A fences; never mode B without `code_absence_note`.

If `--only` was used, add a note in Summary: "Partial review: only {agents} were run."

### Step 5.3 — Save

Write to `{{output_dir}}/final-report.md`.

### Step 5.4 — Output

Display the full final report to the user.

---

## Error Handling

- If target branch does not exist, stop and report the error to the user (should be caught by SKILL.md).
- If no `.go`, dependency, contract, or deployment files are reviewable after Phase 1 filtering, report the no-files message from Phase 1 and stop.
- If a sub-agent fails (timeout, error), log the failure and continue with remaining agents.
  Add a note to the final report: "Agent {name} failed: {reason}. Its category was not reviewed."
- If all Wave 1 agents fail, stop and report the error. Do not launch Wave 2.
- If a sub-agent returns invalid JSON, skip it and note in the report.

---

## Data Retention

**Do NOT delete any files from `{{output_dir}}` after the review.**

All reports must be preserved:
- `reports/` — individual agent JSON reports for debugging/comparison
- `final-report.md` — the rendered report

Temporary files in `{{tmp_dir}}` (metadata.json, diffs/) will be cleaned up by the OS.

**Important for sub-agents:** When writing reports to `reports/`, use the Write tool to create the file. Do NOT use temporary storage — the JSON report must persist on disk at `{{output_dir}}/reports/{agent_name}.json`.

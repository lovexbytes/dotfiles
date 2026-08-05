# Report Format Template

Use this template to render the final conversation response from merged sub-agent JSON reports. Do not write the response to disk unless the user explicitly requests a file.

## Orchestrator contract (non-optional)

For **every** finding (in-scope and out-of-scope, all severities), pick **exactly one** presentation:

**A — Code snippets (default)**
Use when `code_snippet_unavailable` is absent, `false`, or not set:

- Render **Before** and **After** fenced blocks with the language of the changed file.
- If either string is missing, empty, or only whitespace: **reconstruct** minimal snippets from Phase 1 (`tmp_dir/diffs/` plus full file snapshots or the local repo path) at `{file}` around `{line}`, then render those inside the fences.
- **Never** publish empty fenced blocks under mode A.

**B — No applicable snippet (explicit waiver)**
Use only when merged JSON has `code_snippet_unavailable: true`:

- Render **no** Before/After code fences for that finding.
- Render a line: **Code snippet:** not applicable — {code_absence_note}
- Do **not** reconstruct snippets over a waiver; the agent asserted no honest single-location pair exists.

**Do not** use a compact one-line format that drops both A and B (every finding must be either A or B).

Use mode B sparingly (cross-cutting design, policy-only, missing artifact not in diff, multi-file contract). **If a single line or small hunk in the Phase 1 diff at this finding's `file`/`line` would illustrate the issue, mode A is mandatory** — sub-agents must not choose mode B to avoid quoting the diff; the orchestrator should prefer reconstruction (mode A) when diff + file text supply such a line.

---

# Code Review | {title}
**{author}** · `{source_branch}` → `{target_branch}`

## What This Change Does

2–5 sentences describing the implemented behavior and the affected execution path. Focus on **system behavior**, not commit history. Mention the entrypoint, the state transitions, and the downstream side effects (DB, cache, queue, external API).

## System And End-User Impact

- **Runtime / system:** what changes at runtime (new query, new goroutine, new consumer, new schema, new config)
- **Operators / rollout:** what on-call or SRE should know (migration order, rollout order, manifest change, new alert, new dashboard gap)
- **End users / downstream services:** what changes for consumers of the API, event, or shared persistent state — or **"no direct end-user impact"** when true

## Change Overview
**What changed:** {1-3 sentence summary of what the reviewed change introduces or modifies}
**Why:** {1-3 sentence explanation of the goal/purpose}

## Summary

| Metric | Value |
|--------|-------|
| Files checked | {N} |
| Lines added | +{N} |
| Lines removed | -{N} |
| Critical (in scope) | {N} |
| Major (in scope) | {N} |
| Minor (in scope) | {N} |
| Out of scope | {N} |

**Verdict:** {REJECT / REQUEST CHANGES / LGTM}

Verdict rules:
- 1+ in-scope critical → **REJECT**
- 0 in-scope critical, 1+ in-scope major → **REQUEST CHANGES**
- only in-scope minor or clean → **LGTM**
- Out-of-scope findings never affect verdict

---

## Critical ({N})

Only in-scope findings. Group findings by agent category. For each finding:

### {Agent Category Name}

#### [{id}] {title}
- **File:** `{file}:{line}`
- **Category:** {category}
- **Scope:** in scope — {scope_reason}
- **Problem:** {problem — must include production impact}
- **If mode A** (`code_snippet_unavailable` not true): **Before:** / fenced source `{code_before}` — **After:** / fenced source `{code_after}` (after reconstruction if needed; see Orchestrator contract).
- **If mode B** (`code_snippet_unavailable: true`): **Code snippet:** not applicable — {code_absence_note}

---

## Major ({N})

Only in-scope findings. Same branching (mode A vs B) as Critical, grouped by agent category.

---

## Minor ({N})

Only in-scope findings. Same branching (mode A vs B) as Critical, grouped by agent category.

### {Agent Category Name}

#### [{id}] {title}
- **File:** `{file}:{line}`
- **Category:** {category}
- **Scope:** in scope — {scope_reason}
- **Problem:** {problem}
- **If mode A** (`code_snippet_unavailable` not true): **Before:** / fenced source `{code_before}` — **After:** / fenced source `{code_after}` (after reconstruction if needed; see Orchestrator contract).
- **If mode B** (`code_snippet_unavailable: true`): **Code snippet:** not applicable — {code_absence_note}

---

## Out Of Scope Findings ({N})

Only include when final scope validation marked one or more findings `out_of_scope`. These findings are preserved for awareness but excluded from Critical/Major/Minor counts and verdict.

Group by severity (critical → major → minor), then agent category. For each finding:

### {Severity}

#### {Agent Category Name}

##### [{id}] {title}
- **Severity:** {severity}
- **File:** `{file}:{line}`
- **Category:** {category}
- **Scope:** out of scope — {scope_reason}
- **Problem:** {problem}
- **If mode A** (`code_snippet_unavailable` not true): **Before:** / fenced source `{code_before}` — **After:** / fenced source `{code_after}` (after reconstruction if needed; see Orchestrator contract).
- **If mode B** (`code_snippet_unavailable: true`): **Code snippet:** not applicable — {code_absence_note}

---

## Distributed Operations Review

Populate from in-scope `distributed-operations` agent findings. Cover: idempotency, retry safety, replay/reprocessing safety, timeout-budget propagation, degraded dependency behavior, durable handoff, ordering, and compensation.

State one of:

- `No distributed-operations safety issues found.`
- `Only out-of-scope distributed-operations concerns were found; see Out Of Scope Findings.`
- `Distributed-operations review was not run: {reason}. See Verification.`
- A short paragraph describing the runtime-safety concerns, including concrete retry, replay, timeout, or degraded-dependency failure modes.

---

## Backward Compatibility Review

Populate from in-scope `compatibility` agent findings and from any in-scope cross-binary / cross-service concerns raised by `consistency`. Cover: HTTP/gRPC contract, event schema, DB migration, Redis/cache format, config keys, rollout order, rollback safety.

State one of:

- `No backward compatibility issues found.`
- `Only out-of-scope backward compatibility concerns were found; see Out Of Scope Findings.`
- `Backward compatibility review was not run: {reason}. See Verification.`
- `Backward compatibility review did not complete: {reason}. See Verification.`
- A short paragraph describing the concerns, including concrete mixed-version or rollback failure modes and the required rollout order (if any).

---

## Open Questions

Merge `open_questions` arrays from all agent reports. Deduplicate by meaning. Cap at 10 total. Only include this section if there are open questions.

For each question, prefix with the agent name:

- **[{agent}]** {question or residual risk note}

---

## What Was Done Well

Merge `positive` arrays from all agent reports. Deduplicate. Present as bullet list:

- {positive observation from agent}

---

## Key Production Risks

Only include if in-scope critical or major findings exist. Summarize real production consequences:

- {risk description with estimated impact}

---

## Verification

Summarize what was or was not exercised during this review:

- **Ran:** commands the orchestrator or its agents actually executed (e.g. `go test ./...`, `go test -race ./internal/operations/...`, `golangci-lint run`, `go build`). If none, say `None.`.
- **Passed:** commands above that exited zero (or equivalent success signal).
- **Could not verify:** list every `requires_verification: true` finding (title + file:line) and the reason it needs manual follow-up. Also list any agent that failed in Phase 2/3 with its category unreviewed.
- **Gaps:** call out any review dimension skipped due to `--only`, conservative router skip, unavailable tooling, or missing context.

If nothing was run and everything is derived from static review of the diff, state: `Static review only; no commands executed by the orchestrator.`

---

Notes:
- Findings with `requires_verification: true` — append "(requires verification)" to the title **and** list them in the Verification section's "Could not verify" bullet
- Final scope validation must set `scope_status` and `scope_reason` on every merged finding before rendering. Main severity sections render only `scope_status: in_scope`; **Out Of Scope Findings** renders only `scope_status: out_of_scope`.
- If `--only` was used, note which agents were included in the Summary section and in Verification's "Gaps"
- If the conservative router skipped selected agents, list those agents and their skip reasons in Verification's "Gaps"
- If an agent returned 0 findings, do not create an empty section for it
- Agent category order for grouping: correctness, concurrency, conventions, style, tests, deps-supply-chain, sql-data-access, consistency, transactions, domain-invariants, distributed-operations, performance, security, observability, compatibility
- **Completeness:** under mode A, every finding must end with non-empty Before and After fences (after reconstruction if needed). Under mode B, `code_absence_note` must be present and substantive — never a finding with neither fences nor a waiver line

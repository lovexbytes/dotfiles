# Agent Output Contract

Return JSON matching `go-review-refs/agent-output-schema.json`.

Required top-level fields:

```json
{
  "agent": "correctness",
  "files_checked": 1,
  "findings": [],
  "positive": ["Checked changed files against this agent's scope"],
  "open_questions": []
}
```

Finding fields:

- `id`: prefix for the agent plus sequence, for example `CORR-1`
- `severity`: `critical`, `major`, or `minor`
- `title`, `file`, `line`, `category`, `problem`
- `code_before`, `code_after`, `requires_verification`
- Optional `scope_status` / `scope_reason` may be omitted by sub-agents. Final scope classification is added by the orchestrator after deduplication using `go-review-refs/scope-validation.md`.

Code snippet rule:

- Default mode: provide non-empty `code_before` and `code_after`.
- Waiver mode: set `code_snippet_unavailable: true`, set `code_absence_note` to a substantive explanation, and set both code fields to empty strings.
- Use waiver mode only when no honest single-site before/after exists.

Quality rules:

- Findings require about 70% confidence. Lower confidence goes to `open_questions`.
- `problem` must include production impact, attack vector, regression risk, operational gap, or rollout failure mode.
- Focus findings on changed files, changed contracts, or context required to assess them. If you find a high-confidence adjacent issue but are unsure whether it is caused by this review, still report it; final validation will mark `out_of_scope` when appropriate.
- `positive` is required even with no findings.
- Do not fabricate findings to fill the report.

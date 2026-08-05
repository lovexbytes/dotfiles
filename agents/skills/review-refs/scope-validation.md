# Scope Validation Contract

Use this contract after deduplication and before rendering the final report. The goal is to keep useful review signal while making the review verdict depend only on problems caused or exposed by the reviewed change.

## Final Scope Fields

Add these fields to every merged finding:

- `scope_status`: `in_scope` or `out_of_scope`
- `scope_reason`: one concise sentence explaining the classification

Do not ask sub-agents to decide final scope. They can load context files and may surface adjacent issues; the orchestrator owns final classification.

## In Scope

A finding is `in_scope` when at least one condition is true:

- The cited file is changed, and the issue is on a changed line or changed hunk.
- The issue is in unchanged adjacent code that the diff newly calls, exposes, reorders, or relies on.
- The change modifies a contract, schema, dependency, config, deployment artifact, or public API that creates the failure mode.
- The finding is about missing or stale tests for behavior changed by this review.
- The finding blocks safe deploy, rollback, or mixed-version operation of this reviewed change.

## Out Of Scope

A finding is `out_of_scope` when all conditions are true:

- It describes a pre-existing problem not caused, exposed, or made worse by this change.
- The fix would be independent from this review and could land before or after it without changing this review's behavior.
- It was found through exploratory context, not through the changed files, changed contracts, or required rollout path.

Common out-of-scope examples:

- Broad cleanup or refactor advice unrelated to the diff.
- Bug in a caller/callee that existed before and is not newly used by this change.
- Missing tests for unchanged behavior.
- Style or convention issue in untouched code.
- Production risk in an unrelated subsystem discovered during search.

## Borderline Rule

When a finding is severe and plausibly caused or exposed by the change, keep it `in_scope` and make the causal link explicit in `scope_reason`. When the link is weak, mark it `out_of_scope` instead of dropping it.

## Reporting Rules

- Main Critical/Major/Minor sections include only `in_scope` findings.
- `out_of_scope` findings go only in the **Out Of Scope Findings** section, grouped by severity then agent category.
- Verdict and critical/major/minor counts use only `in_scope` findings.
- Summary separately reports `out_of_scope_count`; out-of-scope findings never make the verdict worse.
- Every out-of-scope finding still uses the normal snippet rules from `report-format.md`.

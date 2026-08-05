# Code Review

## Commands

| Skill | Scope | Usage |
|---|---|---|
| `review-local` | Current working tree against a target branch | `<target_branch> [--only agent1,agent2,...] [context]` |
| `review-branch` | Committed current branch against a target branch | `<target_branch> [--only agent1,agent2,...] [context]` |

Both skills use one shared workflow and one canonical support module at `skills/review-refs/`.

## Supported Source

- Go
- TypeScript and JavaScript
- TSX, JSX, HTML, CSS, SCSS, Vue, and Svelte frontend files
- Dependency and lock files
- SQL, protobuf, OpenAPI, build, CI, and deployment contracts

## Flow

1. Capture the complete Git diff.
2. Use `materialize-diffs.py` to write one deterministic diff per file and `diff-index.json`.
3. Use `build-review-context.py` to route only applicable agents.
4. Run active agents in two waves.
5. Validate and merge JSON reports.
6. Classify findings as in scope or out of scope.
7. Return one review report and verdict in the conversation.

The review does not fetch merge requests or tickets. It uses only local Git and local repository files.

## Examples

```text
$review-local main
$review-local main --only typescript,web-accessibility
$review-local main --only correctness,tests,security

$review-branch main
$review-branch main --only compatibility,transactions
$review-branch main --only typescript,web-frontend-performance
```

## Artifacts

Temporary files:

```text
/tmp/review/<timestamp>_local-<branch>/
/tmp/review/<timestamp>_branch-<branch>/
```

Each run writes:

- `full.diff`
- `diff-index.json`
- `diffs/*.diff`
- `contract-files.txt`
- `metadata.json`
- `review-context.json`
- `reports/*.json`

All artifacts stay under the temporary run directory. Normal reviews do not write files inside the reviewed repository. The final report is returned in the conversation. A persistent report is written only when the user explicitly requests one and gives a destination path.

## Routing

- Go source runs the Go review agents and tests agent.
- TypeScript or JavaScript source runs the TypeScript and tests agents.
- Frontend source, including client-side TypeScript, runs UI architecture, forms, accessibility, and frontend performance agents.
- Dependency, lock, build, or CI changes run the supply-chain agent.
- SQL-only changes run data-access, transaction, compatibility, distributed-operation, and domain agents.
- Deployment-only changes run observability, compatibility, and distributed-operation agents.
- `--only` limits the selected set. The router can still skip a selected agent when its source type is absent.

## Verdict

- Any in-scope critical finding: `REJECT`
- Otherwise, any in-scope major finding: `REQUEST CHANGES`
- Otherwise: `LGTM`

Out-of-scope findings stay visible but do not affect the verdict.

## Verification

Run the small router and materializer check:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 skills/review-refs/bin/test_review_tools.py
```

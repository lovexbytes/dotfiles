# Review Context Contract

Build this artifact before any review agent starts.

## Required Inputs

- `diff-index.json` from `bin/materialize-diffs.py`
- Review scope: `local` or `branch`
- Optional comma-separated `--only` agent list

## Builder

```text
python3 review-refs/bin/build-review-context.py \
  --tmp-dir {{tmp_dir}} \
  --scope {{scope}} \
  --selected "{{selected_agents}}" \
  --reports-dir {{tmp_dir}}/reports
```

The builder also writes `contract-files.txt` from changed dependency, SQL, protobuf, API, build, CI, and deployment files.

## Shape

```json
{
  "scope": "local",
  "changed_source_files": [
    {
      "path": "client/src/user.tsx",
      "old_path": "client/src/user.tsx",
      "language": "typescript",
      "status": "modified",
      "diff_path": "/tmp/review/.../diffs/client%2Fsrc%2Fuser.tsx.diff",
      "lines_added": 12,
      "lines_removed": 4
    }
  ],
  "contract_files": ["client/package.json"],
  "selected_agents": ["typescript", "web-accessibility", "tests"],
  "agent_plan": {
    "typescript": {
      "decision": "run",
      "reason": "TypeScript or JavaScript source is present",
      "files": ["client/src/user.tsx"]
    }
  }
}
```

## Routing

- Go source runs Go agents.
- TypeScript or JavaScript source runs `typescript` and `tests`.
- Frontend source, including TypeScript under known frontend paths, runs the four `web-*` agents.
- Dependency, lock, build, or CI changes run `deps-supply-chain`.
- SQL, service-contract, and deployment changes run applicable data, compatibility, distributed-operation, domain, and observability agents even when no Go source changed.
- `--only` limits the selected set.
- Every selected agent receives one deterministic `run` or `skip` decision.

Skipped agents still write temporary zero-finding reports under `{{tmp_dir}}/reports`. This keeps aggregation complete and makes the reason visible.

## File Access

Agents read changed files from the local repository. For deleted files, load prior content from the target branch only when the diff is not sufficient. Load extra callers, contracts, and configuration only when the matching file under `context-rules/` requires them.

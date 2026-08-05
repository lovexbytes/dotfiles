#!/usr/bin/env python3
"""Small behavior checks for review diff materialization and routing."""
from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).parent


def load_script(filename: str, name: str):
    path = HERE / filename
    assert path.exists(), f"missing review tool: {filename}"
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def write_index(tmp: Path, paths: list[str], contract_paths: list[str] | None = None) -> None:
    diffs = tmp / "diffs"
    diffs.mkdir()
    entries = []
    for path in paths:
        diff_path = diffs / f"{path.replace('/', '-')}.diff"
        diff_path.write_text(
            f"diff --git a/{path} b/{path}\n"
            f"--- a/{path}\n"
            f"+++ b/{path}\n"
            "@@ -1 +1 @@\n"
            "-old\n"
            "+new\n"
        )
        entries.append(
            {
                "path": path,
                "old_path": path,
                "diff_path": str(diff_path),
                "is_source": Path(path).suffix in {".go", ".ts", ".tsx", ".js", ".jsx", ".html", ".css", ".scss"},
                "lines_added": 1,
                "lines_removed": 1,
            }
        )
    (tmp / "diff-index.json").write_text(json.dumps({"files": entries}))
    (tmp / "contract-files.txt").write_text("\n".join(contract_paths or []))


class ReviewRouterTests(unittest.TestCase):
    def test_typescript_ui_runs_typescript_web_and_tests_without_go(self) -> None:
        router = load_script("build-review-context.py", "review_router_ts")
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            write_index(tmp, ["client/components/UploadForm.tsx"])
            ctx = router.build(tmp, "local", None)

        for agent in (
            "typescript",
            "tests",
            "web-ui-architecture",
            "web-forms-validation",
            "web-accessibility",
            "web-frontend-performance",
        ):
            self.assertEqual(ctx["agent_plan"][agent]["decision"], "run")
        self.assertEqual(ctx["agent_plan"]["concurrency"]["decision"], "skip")

    def test_go_runs_go_and_tests_without_typescript_or_web(self) -> None:
        router = load_script("build-review-context.py", "review_router_go")
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            write_index(tmp, ["internal/service/upload.go"])
            ctx = router.build(tmp, "branch", None)

        self.assertEqual(ctx["agent_plan"]["correctness"]["decision"], "run")
        self.assertEqual(ctx["agent_plan"]["tests"]["decision"], "run")
        self.assertEqual(ctx["agent_plan"]["typescript"]["decision"], "skip")
        self.assertEqual(ctx["agent_plan"]["web-accessibility"]["decision"], "skip")

    def test_package_manifest_runs_dependency_review(self) -> None:
        router = load_script("build-review-context.py", "review_router_deps")
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            write_index(tmp, ["client/package.json"])
            ctx = router.build(tmp, "local", None)

        self.assertEqual(ctx["agent_plan"]["deps-supply-chain"]["decision"], "run")

    def test_sql_contract_runs_data_and_rollout_agents_without_go(self) -> None:
        router = load_script("build-review-context.py", "review_router_sql")
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            write_index(tmp, ["db/migrations/001_add_user.sql"])
            ctx = router.build(tmp, "local", None)

        for agent in (
            "sql-data-access",
            "transactions",
            "compatibility",
            "distributed-operations",
            "domain-invariants",
        ):
            self.assertEqual(ctx["agent_plan"][agent]["decision"], "run")

    def test_plain_typescript_in_client_path_runs_web_agents(self) -> None:
        router = load_script("build-review-context.py", "review_router_client_ts")
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            write_index(tmp, ["client/forms/register-validation.ts"])
            ctx = router.build(tmp, "local", None)

        for agent in router.WEB_AGENTS:
            self.assertEqual(ctx["agent_plan"][agent]["decision"], "run")

    def test_deploy_contract_runs_observability_without_go(self) -> None:
        router = load_script("build-review-context.py", "review_router_deploy")
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            write_index(tmp, ["deploy/service.yaml"])
            ctx = router.build(tmp, "local", None)

        self.assertEqual(ctx["agent_plan"]["observability"]["decision"], "run")

    def test_context_shape_matches_contract(self) -> None:
        router = load_script("build-review-context.py", "review_router_shape")
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            write_index(tmp, ["api/openapi.yaml"])
            ctx = router.build(tmp, "local", ["compatibility"])

        self.assertEqual(ctx["contract_files"], ["api/openapi.yaml"])
        self.assertEqual(ctx["selected_agents"], ["compatibility"])

    def test_renamed_sql_contract_remains_reviewable(self) -> None:
        router = load_script("build-review-context.py", "review_router_sql_rename")
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            write_index(tmp, ["db/migrations/001_add_user.txt"])
            index_path = tmp / "diff-index.json"
            index = json.loads(index_path.read_text())
            index["files"][0]["old_path"] = "db/migrations/001_add_user.sql"
            index["files"][0]["status"] = "renamed"
            index_path.write_text(json.dumps(index))
            ctx = router.build(tmp, "local", None)

        self.assertEqual(ctx["contract_files"], ["db/migrations/001_add_user.sql"])
        self.assertEqual(ctx["agent_plan"]["sql-data-access"]["decision"], "run")


class DiffMaterializerTests(unittest.TestCase):
    def test_git_diff_is_split_and_web_file_is_source(self) -> None:
        materializer = load_script("materialize-diffs.py", "review_materializer")
        diff = (
            "diff --git a/client/form.tsx b/client/form.tsx\n"
            "--- a/client/form.tsx\n"
            "+++ b/client/form.tsx\n"
            "@@ -1 +1 @@\n"
            "-old\n"
            "+new\n"
        )
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            source = tmp / "full.diff"
            source.write_text(diff)
            index = materializer.materialize(source, tmp)

        self.assertEqual(len(index["files"]), 1)
        self.assertTrue(index["files"][0]["is_source"])
        self.assertEqual(index["lines_added"], 1)
        self.assertEqual(index["lines_removed"], 1)

    def test_deleted_file_keeps_old_path_and_status(self) -> None:
        materializer = load_script("materialize-diffs.py", "review_materializer_delete")
        diff = (
            "diff --git a/internal/old.go b/internal/old.go\n"
            "deleted file mode 100644\n"
            "--- a/internal/old.go\n"
            "+++ /dev/null\n"
            "@@ -1 +0,0 @@\n"
            "-old\n"
        )
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            source = tmp / "full.diff"
            source.write_text(diff)
            index = materializer.materialize(source, tmp)

        self.assertEqual(index["files"][0]["path"], "internal/old.go")
        self.assertEqual(index["files"][0]["status"], "deleted")

    def test_git_quoted_utf8_path_is_decoded(self) -> None:
        materializer = load_script("materialize-diffs.py", "review_materializer_utf8")
        diff = (
            'diff --git "a/caf\\303\\251.go" "b/caf\\303\\251.go"\n'
            '--- "a/caf\\303\\251.go"\n'
            '+++ "b/caf\\303\\251.go"\n'
            "@@ -1 +1 @@\n"
            "-old\n"
            "+new\n"
        )
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            source = tmp / "full.diff"
            source.write_text(diff)
            index = materializer.materialize(source, tmp)

        self.assertEqual(index["files"][0]["path"], "café.go")

    def test_git_quoted_literal_unicode_path_is_decoded(self) -> None:
        materializer = load_script("materialize-diffs.py", "review_materializer_unicode")
        self.assertEqual(
            materializer.normalize_path('"a/café file.go"'),
            "café file.go",
        )

    def test_rename_from_source_to_non_source_remains_reviewable(self) -> None:
        materializer = load_script("materialize-diffs.py", "review_materializer_rename")
        router = load_script("build-review-context.py", "review_router_rename")
        diff = (
            "diff --git a/client/form.ts b/client/form.txt\n"
            "similarity index 100%\n"
            "rename from client/form.ts\n"
            "rename to client/form.txt\n"
        )
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            source = tmp / "full.diff"
            source.write_text(diff)
            index = materializer.materialize(source, tmp)
            ctx = router.build(tmp, "local", None)

        self.assertEqual(index["files"][0]["status"], "renamed")
        self.assertTrue(index["files"][0]["is_source"])
        self.assertEqual(ctx["agent_plan"]["typescript"]["decision"], "run")


if __name__ == "__main__":
    unittest.main()

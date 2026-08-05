#!/usr/bin/env python3
"""Build review-context.json with conservative language routing."""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ALL_AGENTS = [
    "correctness",
    "concurrency",
    "conventions",
    "style",
    "performance",
    "security",
    "tests",
    "typescript",
    "observability",
    "deps-supply-chain",
    "sql-data-access",
    "consistency",
    "transactions",
    "compatibility",
    "distributed-operations",
    "domain-invariants",
    "web-ui-architecture",
    "web-forms-validation",
    "web-accessibility",
    "web-frontend-performance",
]
GO_ONLY_AGENTS = [
    "correctness",
    "concurrency",
    "conventions",
    "style",
    "performance",
    "security",
    "consistency",
]
WEB_AGENTS = [
    "web-ui-architecture",
    "web-forms-validation",
    "web-accessibility",
    "web-frontend-performance",
]
TS_EXTENSIONS = {".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs"}
WEB_EXTENSIONS = {".tsx", ".jsx", ".html", ".css", ".scss", ".vue", ".svelte"}
DEPENDENCY_FILE = re.compile(
    r"(^|/)(go\.(mod|sum)|package\.json|package-lock\.json|pnpm-lock\.yaml|"
    r"yarn\.lock|bun\.lockb?|Dockerfile|compose\.ya?ml)$|(^|/)\.github/workflows/"
)
CONTRACT_FILE = re.compile(
    r"\.(proto|sql)$|(^|/)(go\.(mod|sum|work|work\.sum)|package\.json|"
    r"package-lock\.json|pnpm-lock\.yaml|yarn\.lock|bun\.lockb?|Dockerfile|"
    r"Makefile|tsconfig[^/]*\.json|eslint[^/]*|next\.config\.[^/]+|"
    r"sqlc[^/]*\.ya?ml|openapi[^/]*\.ya?ml|swagger[^/]*\.ya?ml)$|"
    r"(^|/)(deploy|helm|k8s|kubernetes|charts|manifests|\.github/workflows)/"
)
SQL_CONTRACT = re.compile(r"\.sql$|(^|/)sqlc[^/]*\.ya?ml$")
SERVICE_CONTRACT = re.compile(r"\.proto$|(^|/)(openapi|swagger)[^/]*\.ya?ml$")
DEPLOY_CONTRACT = re.compile(
    r"(^|/)(Dockerfile|compose\.ya?ml)$|"
    r"(^|/)(deploy|helm|k8s|kubernetes|charts|manifests|\.github/workflows)/"
)
WEB_PATH_PARTS = {
    "app",
    "client",
    "components",
    "frontend",
    "forms",
    "hooks",
    "pages",
    "ui",
    "web",
}


def detect_language(path: str) -> str:
    suffix = Path(path).suffix.lower()
    if suffix == ".go":
        return "go"
    if suffix in TS_EXTENSIONS:
        return "typescript" if suffix in {".ts", ".tsx"} else "javascript"
    if suffix in WEB_EXTENSIONS:
        return "web"
    return "other"


def detect_status(path: str, old_path: str) -> str:
    if not old_path or old_path == "/dev/null":
        return "added"
    if not path or path == "/dev/null":
        return "deleted"
    if path != old_path:
        return "renamed"
    return "modified"


def plan(decision: str, reason: str, files: list[str] | None = None) -> dict:
    return {"decision": decision, "reason": reason, "files": files or []}


def is_web_path(path: str) -> bool:
    suffix = Path(path).suffix.lower()
    if suffix in WEB_EXTENSIONS:
        return True
    parts = {part.lower() for part in Path(path).parts}
    return suffix in TS_EXTENSIONS and bool(WEB_PATH_PARTS.intersection(parts))


def combine_paths(*groups: list[str]) -> list[str]:
    return list(dict.fromkeys(path for group in groups for path in group))


def build(tmp: Path, scope: str, selected: list[str] | None) -> dict:
    index = json.loads((tmp / "diff-index.json").read_text(encoding="utf-8"))
    contract_file = tmp / "contract-files.txt"
    explicit_contract_paths = (
        [line.strip() for line in contract_file.read_text().splitlines() if line.strip()]
        if contract_file.exists()
        else []
    )
    indexed_contract_paths = []
    for item in index.get("files", []):
        path = item.get("path") or ""
        old_path = item.get("old_path") or ""
        if path and CONTRACT_FILE.search(path):
            indexed_contract_paths.append(path)
        elif old_path and CONTRACT_FILE.search(old_path):
            indexed_contract_paths.append(old_path)
    contract_paths = sorted(
        set(explicit_contract_paths).union(indexed_contract_paths)
    )
    contract_file.write_text(
        "\n".join(contract_paths) + ("\n" if contract_paths else ""), encoding="utf-8"
    )

    changed_source = []
    go_files = []
    ts_files = []
    web_files = []
    for item in index.get("files", []):
        if not item.get("is_source"):
            continue
        path = item.get("path") or item.get("old_path") or ""
        old_path = item.get("old_path") or path
        language_path = path if detect_language(path) != "other" else old_path
        file_language = detect_language(language_path)
        if file_language == "other":
            continue
        entry = {
            "path": path,
            "old_path": old_path,
            "language": file_language,
            "status": item.get("status") or detect_status(path, old_path),
            "diff_path": item.get("diff_path") or "",
            "lines_added": item.get("lines_added", 0),
            "lines_removed": item.get("lines_removed", 0),
        }
        changed_source.append(entry)
        if file_language == "go":
            go_files.append(entry)
        if file_language in {"typescript", "javascript"}:
            ts_files.append(entry)
        if is_web_path(path) or is_web_path(old_path):
            web_files.append(entry)

    selected_set = set(selected or ALL_AGENTS)
    unknown = selected_set.difference(ALL_AGENTS)
    if unknown:
        raise ValueError(f"unknown agents: {', '.join(sorted(unknown))}")

    go_paths = [entry["path"] for entry in go_files]
    ts_paths = [entry["path"] for entry in ts_files]
    web_paths = [entry["path"] for entry in web_files]
    agent_plan = {}

    for agent in GO_ONLY_AGENTS:
        if agent in selected_set:
            agent_plan[agent] = (
                plan("run", "Go source changed", go_paths)
                if go_paths
                else plan("skip", "No Go source changed")
            )

    sql_paths = [path for path in contract_paths if SQL_CONTRACT.search(path)]
    service_paths = [path for path in contract_paths if SERVICE_CONTRACT.search(path)]
    deploy_paths = [path for path in contract_paths if DEPLOY_CONTRACT.search(path)]
    review_contract_paths = combine_paths(sql_paths, service_paths, deploy_paths)
    contract_agent_paths = {
        "observability": combine_paths(go_paths, deploy_paths),
        "sql-data-access": combine_paths(go_paths, sql_paths),
        "transactions": combine_paths(go_paths, sql_paths),
        "compatibility": combine_paths(go_paths, review_contract_paths),
        "distributed-operations": combine_paths(go_paths, review_contract_paths),
        "domain-invariants": combine_paths(go_paths, sql_paths, service_paths),
    }
    for agent, paths in contract_agent_paths.items():
        if agent in selected_set:
            agent_plan[agent] = (
                plan("run", "Go source or relevant service contract changed", paths)
                if paths
                else plan("skip", "No Go source or relevant service contract changed")
            )

    if "tests" in selected_set:
        test_paths = go_paths + ts_paths
        agent_plan["tests"] = (
            plan("run", "Go or TypeScript/JavaScript source changed", test_paths)
            if test_paths
            else plan("skip", "No Go or TypeScript/JavaScript source changed")
        )

    if "typescript" in selected_set:
        agent_plan["typescript"] = (
            plan("run", "TypeScript/JavaScript source changed", ts_paths)
            if ts_paths
            else plan("skip", "No TypeScript/JavaScript source changed")
        )

    if "deps-supply-chain" in selected_set:
        dependency_paths = [path for path in contract_paths if DEPENDENCY_FILE.search(path)]
        agent_plan["deps-supply-chain"] = (
            plan("run", "Dependency or build files changed", dependency_paths)
            if dependency_paths
            else plan("skip", "No dependency or build files changed")
        )

    for agent in WEB_AGENTS:
        if agent in selected_set:
            agent_plan[agent] = (
                plan("run", "Frontend source changed", web_paths)
                if web_paths
                else plan("skip", "No frontend source changed")
            )

    for agent in ALL_AGENTS:
        if agent in selected_set:
            agent_plan.setdefault(agent, plan("skip", "Not applicable for this change set"))

    return {
        "scope": scope,
        "changed_source_files": changed_source,
        "changed_go_files": go_files,
        "changed_typescript_files": ts_files,
        "changed_web_files": web_files,
        "contract_files": contract_paths,
        "selected_agents": [agent for agent in ALL_AGENTS if agent in selected_set],
        "agent_plan": agent_plan,
    }


def write_skip_reports(context: dict, reports_dir: Path) -> int:
    reports_dir.mkdir(parents=True, exist_ok=True)
    count = 0
    for agent, agent_plan in context["agent_plan"].items():
        if agent_plan["decision"] != "skip":
            continue
        report = {
            "agent": agent,
            "files_checked": 0,
            "findings": [],
            "positive": [f"Skipped by router: {agent_plan['reason']}"],
            "open_questions": [],
        }
        (reports_dir / f"{agent}.json").write_text(
            json.dumps(report, indent=2) + "\n", encoding="utf-8"
        )
        count += 1
    return count


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tmp-dir", required=True, type=Path)
    parser.add_argument("--scope", required=True, choices=("local", "branch"))
    parser.add_argument("--selected", help="Comma-separated agent names")
    parser.add_argument("--reports-dir", type=Path)
    args = parser.parse_args()

    selected = (
        [name.strip() for name in args.selected.split(",") if name.strip()]
        if args.selected
        else None
    )
    context = build(args.tmp_dir, args.scope, selected)
    (args.tmp_dir / "review-context.json").write_text(
        json.dumps(context, indent=2) + "\n", encoding="utf-8"
    )
    if args.reports_dir:
        write_skip_reports(context, args.reports_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

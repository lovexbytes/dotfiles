#!/usr/bin/env python3
"""Split a Git unified diff into per-file diffs and a compact index."""
from __future__ import annotations

import argparse
import ast
import json
import re
from pathlib import Path
from urllib.parse import quote

SOURCE_EXTENSIONS = {
    ".go",
    ".ts",
    ".tsx",
    ".js",
    ".jsx",
    ".mjs",
    ".cjs",
    ".html",
    ".css",
    ".scss",
    ".vue",
    ".svelte",
}
EXCLUDED = [
    re.compile(pattern)
    for pattern in (
        r"^vendor/",
        r"^node_modules/",
        r"^dist/",
        r"^build/",
        r"^coverage/",
        r"_mock\.go$",
        r"\.pb\.go$",
        r"_generated\.go$",
        r"^testdata/",
        r"\.gen\.go$",
        r"\.generated\.(ts|tsx|js|jsx)$",
        r"\.gen\.(ts|tsx|js|jsx)$",
        r"\.min\.js$",
    )
]
DIFF_HEADER = re.compile(
    r'^diff --git ("(?:\\.|[^"])*"|\S+) ("(?:\\.|[^"])*"|\S+)$'
)


def normalize_path(raw: str) -> str:
    path = raw.strip().split("\t", 1)[0]
    if path.startswith('"'):
        decoded = ast.literal_eval(path)
        path = (
            decoded.encode("latin-1").decode("utf-8", errors="surrogateescape")
            if re.search(r"\\[0-7]{3}", path)
            else decoded
        )
    if path.startswith(("a/", "b/")):
        path = path[2:]
    return path


def is_source(path: str) -> bool:
    return Path(path).suffix.lower() in SOURCE_EXTENSIONS and not any(
        pattern.search(path) for pattern in EXCLUDED
    )


def build_diff_filename(path: str) -> str:
    return f"{quote(path, safe='')}.diff"


def parse_diff_header(line: str) -> tuple[str, str] | None:
    match = DIFF_HEADER.match(line.rstrip("\n"))
    if not match:
        return None
    return normalize_path(match.group(1)), normalize_path(match.group(2))


def count_lines(diff: str) -> tuple[int, int]:
    added = removed = 0
    for line in diff.splitlines():
        if line.startswith("+") and not line.startswith("+++"):
            added += 1
        elif line.startswith("-") and not line.startswith("---"):
            removed += 1
    return added, removed


def split_git_diff(text: str) -> list[tuple[str, str, str, str]]:
    chunks: list[list[str]] = []
    current: list[str] = []
    for line in text.splitlines(keepends=True):
        if line.startswith("diff --git "):
            if current:
                chunks.append(current)
            current = [line]
        elif current:
            current.append(line)
    if current:
        chunks.append(current)

    result: list[tuple[str, str, str, str]] = []
    for lines in chunks:
        paths = parse_diff_header(lines[0])
        if not paths:
            continue
        old_path, path = paths
        for line in lines:
            if line.startswith("--- "):
                old_path = normalize_path(line[4:])
            elif line.startswith("+++ "):
                path = normalize_path(line[4:])
        if path == "/dev/null":
            status = "deleted"
        elif old_path == "/dev/null":
            status = "added"
        elif path != old_path:
            status = "renamed"
        else:
            status = "modified"
        effective_path = old_path if status == "deleted" else path
        if effective_path and effective_path != "/dev/null":
            result.append((effective_path, old_path, status, "".join(lines)))
    return result


def materialize(source: Path, output: Path) -> dict:
    text = source.read_text(encoding="utf-8", errors="replace")
    chunks = split_git_diff(text)
    if text.strip() and not chunks:
        raise ValueError("non-empty input is not a Git unified diff")

    diffs_dir = output / "diffs"
    diffs_dir.mkdir(parents=True, exist_ok=True)
    entries = []
    for path, old_path, status, diff in chunks:
        added, removed = count_lines(diff)
        diff_path = diffs_dir / build_diff_filename(path)
        diff_path.write_text(diff, encoding="utf-8")
        entries.append(
            {
                "path": path,
                "old_path": old_path,
                "status": status,
                "diff_path": str(diff_path),
                "lines_added": added,
                "lines_removed": removed,
                "is_source": is_source(path) or is_source(old_path),
            }
        )

    source_entries = [entry for entry in entries if entry["is_source"]]
    index = {
        "files": entries,
        "source_files": source_entries,
        "lines_added": sum(entry["lines_added"] for entry in source_entries),
        "lines_removed": sum(entry["lines_removed"] for entry in source_entries),
    }
    (output / "diff-index.json").write_text(
        json.dumps(index, indent=2) + "\n", encoding="utf-8"
    )
    return index


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--unified", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()
    index = materialize(args.unified, args.out)
    print(
        f"materialized {len(index['files'])} files "
        f"({len(index['source_files'])} source) "
        f"+{index['lines_added']}/-{index['lines_removed']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

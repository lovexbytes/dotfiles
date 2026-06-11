#!/usr/bin/env bash
# Audit a repo docs/index.md structure for agent navigation.

set -u

repo="${1:-.}"
repo="$(cd "$repo" 2>/dev/null && pwd)"
docs="$repo/docs"
index="$docs/index.md"
fail_count=0
warn_count=0

fail() {
  printf 'FAIL: %s\n' "$1"
  fail_count=$((fail_count + 1))
}

warn() {
  printf 'WARN: %s\n' "$1"
  warn_count=$((warn_count + 1))
}

relpath() {
  local path="$1"
  printf '%s\n' "${path#"$repo"/}"
}

required_docs=(
  "docs/index.md"
  "docs/entrypoints.md"
  "docs/layers.md"
  "docs/integrations.md"
  "docs/config-and-secrets.md"
  "docs/observability.md"
  "docs/deployment-and-infra.md"
  "docs/ownership.md"
  "docs/where-to-change.md"
)

for required in "${required_docs[@]}"; do
  if [[ ! -e "$repo/$required" ]]; then
    fail "missing required file: $required"
  fi
done

if [[ ! -d "$docs" || ! -e "$index" ]]; then
  if [[ "$fail_count" -gt 0 ]]; then
    exit 1
  fi
  exit 0
fi

index_text="$(cat "$index")"

utc_line="$(grep -E '\*\*UTC:\*\*' "$index" | head -n 1 || true)"
git_line="$(grep -E '\*\*Git:\*\*' "$index" | head -n 1 || true)"

if ! printf '%s\n' "$utc_line" | grep -Eq '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'; then
  fail "docs/index.md missing Generated UTC line"
fi

index_git="$(printf '%s\n' "$git_line" | grep -Eo '[0-9a-f]{40}' | head -n 1 || true)"
if [[ -z "$index_git" ]]; then
  fail "docs/index.md missing Generated Git SHA"
else
  head_git="$(git -C "$repo" rev-parse HEAD 2>/dev/null || true)"
  if [[ -n "$head_git" && "$index_git" != "$head_git" ]]; then
    fail "docs/index.md Generated Git is stale: $index_git != HEAD $head_git"
  fi
fi

domains_dir="$docs/domains"
if [[ ! -d "$domains_dir" ]] || ! find "$domains_dir" -type f -name '*.md' | grep -q .; then
  fail "docs/domains has no domain markdown files"
else
  while IFS= read -r domain; do
    domain_rel="$(relpath "$domain")"
    domain_link="${domain_rel#docs/}"
    if ! printf '%s\n' "$index_text" | grep -Fq "$domain_link"; then
      fail "domain doc not linked from docs/index.md: $domain_rel"
    fi
  done < <(find "$domains_dir" -type f -name '*.md' | sort)
fi

while IFS= read -r md; do
  while IFS= read -r link; do
    [[ "$link" == !* ]] && continue
    target="$(printf '%s\n' "$link" | sed -E 's/^.*\]\(([^)]*)\)$/\1/')"
    target="${target%%#*}"
    target="${target//%20/ }"
    [[ -z "$target" ]] && continue
    case "$target" in
      http://*|https://*|mailto:*|\#*) continue ;;
    esac
    target_path="$(cd "$(dirname "$md")" && cd "$(dirname "$target")" 2>/dev/null && pwd)/$(basename "$target")"
    if [[ ! -e "$target_path" ]]; then
      fail "broken link in $(relpath "$md"): $target"
    fi
  done < <(grep -Eo '!?\[[^]]+\]\([^)]+\)' "$md" || true)
done < <(find "$docs" -type f -name '*.md' | sort)

for md in "$docs"/*.md; do
  [[ -e "$md" ]] || continue
  name="$(basename "$md")"
  [[ "$name" == "index.md" ]] && continue
  if ! printf '%s\n' "$index_text" | grep -Fq "$name"; then
    warn "top-level doc not linked from docs/index.md: $(relpath "$md")"
  fi
done

for subdir in "$docs"/*; do
  [[ -d "$subdir" ]] || continue
  name="$(basename "$subdir")"
  case "$name" in
    domains|review|reviews|superpowers|plans|tmp|generated) continue ;;
  esac
  warn "docs subtree not covered by default index rules: $(relpath "$subdir")"
done

agents="$repo/AGENTS.md"
if [[ ! -e "$agents" ]]; then
  fail "repo AGENTS.md missing index instructions"
else
  for phrase in "docs/index.md" "ripgrep" "update the affected markdown" "Generated" "indexing-codebase-repos"; do
    if ! grep -Fq "$phrase" "$agents"; then
      warn "AGENTS.md may miss index rule phrase: '$phrase'"
    fi
  done
  if [[ -e "$repo/go.mod" || -e "$repo/go.work" ]]; then
    if ! grep -Fq "gopls" "$agents"; then
      warn "Go repo AGENTS.md may miss gopls MCP navigation guidance"
    fi
  fi
fi

if [[ "$fail_count" -eq 0 && "$warn_count" -eq 0 ]]; then
  printf 'OK repo index audit passed\n'
elif [[ "$fail_count" -eq 0 ]]; then
  printf 'OK repo index audit passed with %d warning(s)\n' "$warn_count"
fi

if [[ "$fail_count" -gt 0 ]]; then
  exit 1
fi

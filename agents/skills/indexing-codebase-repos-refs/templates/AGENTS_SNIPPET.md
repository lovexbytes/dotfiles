# Snippet for repo-root AGENTS.md

Copy the following into **`AGENTS.md`** (merge with existing sections such as “Build and test”; keep one clear **Repository index** block). Replace the service label in the mandatory steps (e.g. `` `core` ``) with your service or repo name.

```markdown
## Repository index (read this before deep exploration)

**Hub file (open first):** [docs/index.md](docs/index.md)

That page links to domain docs, layers, and cross-cutting topics. It is the maintained map of **what lives where** and **how flows connect**.

### Mandatory steps for AI / autonomous agents

1. **First action** when you start any task in this service: **read `docs/index.md`** end-to-end, then open every linked doc that matches the user’s topic (same session, before writing code or large refactors).
2. **Do not** treat ripgrep, file globbing, or semantic search alone as sufficient orientation for this service if the index covers your area—use search **after** the index pointed you at the right domains and files.
3. For Go symbol/API/caller questions, prefer gopls MCP (`go_search`, `go_symbol_references`, `go_package_api`, `go_file_context`, `go_workspace`, `go_diagnostics`) after the index points you at the area. Use `rg` for non-Go text, docs/config, path discovery, or when gopls is unavailable/empty. Keep notes portable: repo-relative paths and tool names only, no user-local absolute paths or local MCP server IDs.
4. When your change **alters** behavior, boundaries, entrypoints, integrations, config, observability, deployment, or “where to change” guidance that appears in the index or its linked pages, **update the affected markdown under `docs/` in the same change** so the index stays true.
5. Before finishing a code change, compare changed paths with `docs/where-to-change.md`, the matching domain page(s), and cross-cutting docs. If the docs no longer describe the repo, patch them before final response.
6. When the user explicitly asks to **regenerate or refresh** the full index, follow the skill **indexing-codebase-repos**: reconcile all index pages, run its OS-specific audit script, then update the **Generated** metadata (UTC time and full git SHA) in `docs/index.md`.

### Humans

Same as above, but step 1–2 are “prefer reading the index first”; step 3–5 still apply when you change documented behavior.
```

**Note:** If `AGENTS.md` is not at the repo root, adjust the link to reach `docs/index.md` correctly.

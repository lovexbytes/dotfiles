---
name: db-sqlc
description: Use when a repository uses sqlc and work needs SQL query changes, generated sqlc output regeneration, or a new sqlc-backed repository/module.
---

# SQLC Repository Work

## Overview

In repositories that use `sqlc`, repository behavior is defined by SQL query files and generated into Go code.
Generated files are output artifacts and must not be edited manually.

## When to Use

Use this skill when:

- changing behavior of existing SQL-backed repositories
- adding new repository methods through `sqlc` queries
- creating a new SQL-backed repository module from scratch
- regenerating `sqlc` output after query/schema changes

Do not use this skill for non-SQL repository logic.

## Discover The Layout

Before editing, discover the repository's sqlc layout instead of assuming paths:

- `find . -name sqlc.yaml -o -name sqlc.yml`
- inspect each config for query, schema, and output paths
- check nearby `//go:generate sqlc generate` directives
- check `Makefile`, task files, CI, or scripts for the repo's generation command

Common layouts include:

- `<module>/queries/*.sql`
- `<module>/sqlc.yaml`
- `<module>/sqlc/*.go` or `<module>/db/*.go` generated output
- shared migrations under `migrations/`, `db/migrations/`, or `cmd/migrations/`

## Go MCP Navigation

- After locating the sqlc package, use gopls MCP for generated Go API and caller impact: `go_package_api`, `go_symbol_references`, `go_file_context`, and `go_diagnostics`.
- Use SQL/file search for query names, table/column strings, migrations, and sqlc config because those are not Go symbols.

## SQL Authoring Patterns

1. Query header:
   `-- name: MethodName :exec|:one|:many`
2. Optional scalar filter:
   `(sqlc.narg(field)::type IS NULL OR column = sqlc.narg(field)::type)`
3. Optional array filter:
   `(sqlc.narg(ids)::uuid[] IS NULL OR column = ANY(sqlc.narg(ids)::uuid[]))`
4. Required named argument:
   `sqlc.arg(sort_key)::text`
5. Partial update:
   `column = COALESCE(sqlc.narg(column)::type, column)`
6. Pagination:
   `LIMIT sqlc.narg(limit_value)::bigint`
   `OFFSET COALESCE(sqlc.narg(offset_value)::bigint, 0)`
7. Dynamic sort:
   `ORDER BY CASE WHEN sqlc.arg(sort_key)::text = 'field' THEN column END DESC`
8. Total row count in lists:
   `COUNT(*) OVER() AS total_count`
9. Transaction lock:
   `SELECT ... FOR UPDATE`

## Generation Commands

Use the repository's pinned or implied `sqlc` version:

- existing tool install docs
- `go.mod` tool dependencies
- CI images or setup scripts
- generated-file version headers

Prefer the repo's generation command when present:

- `go generate ./path/to/package`
- `make sqlc`, `make generate`, `task generate`, or equivalent

When no wrapper exists, run sqlc directly against each affected config:

- `sqlc generate -f path/to/sqlc.yaml`

## Create New SQLC Repository Module (From Scratch)

1. Create `<module>/storage/queries` and add `*.sql` files with named queries.
2. Add `<module>/storage/sqlc.yaml` by mirroring existing configs:
   - query path/glob style
   - schema path
   - generated output package/path
   - type overrides and emit settings
3. Add `//go:generate sqlc generate` in `<module>/storage/*.go`.
4. Run `sqlc generate -f <module>/storage/sqlc.yaml`.
5. Wire generated package in module repository code (`queries *sqlc.Queries`, mappings).
6. Add tests for the new behavior.

## Validation Checklist

- regenerate affected `sqlc` outputs
- ensure no manual edits in generated `sqlc/*.go` files
- run targeted tests for touched modules
- verify SQL changes and generated diffs are committed together

## Common Mistakes

- editing generated sqlc Go files directly
- missing explicit casts with `sqlc.narg(...)::type`
- overusing positional `$1/$2` and getting weak parameter names like `dollar_1`
- regenerating only one sqlc package when multiple are affected
- assuming `make` or `go generate` behavior instead of checking the repository

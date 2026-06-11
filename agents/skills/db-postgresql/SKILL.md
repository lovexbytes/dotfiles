---
name: db-postgresql
description: Use when repository work needs PostgreSQL schema or data inspection, Docker Compose Postgres startup, migration creation/application, DB backfills, indexes, enums, or migration SQL files; also when invoked as $db-postgresql.
---

# DB PostgreSQL

## Overview

Postgres state is inspected against the repository's local Docker DB and changed through SQL migrations. Prefer repository-provided migration targets and derive DB connection details from Compose/config instead of assuming shared defaults.

## When to Use

Use this skill when:

- inspecting Postgres schema, data, indexes, enums, or `schema_migrations`
- starting/checking local Postgres from repository `docker-compose.yaml`
- adding a new DB migration
- changing existing migration content before it is merged/deployed
- performing schema/data/index backfills through migrations
- verifying how migrations are applied from `Makefile`
- user explicitly asks for `$db-postgresql`

Do not use this skill for runtime repository queries (`sqlc` only changes) without DB schema/data changes.

## Docker DB Workflow

From repository root:

1. If `docker-compose.yaml`/`docker-compose.yml` exists, inspect it for a Postgres service (`postgres:` or `image: postgres...`).
2. Extract service name, DB name, user, password, and port from that Compose service. Use `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_PORT`, port mappings, and referenced `.env` values; do not assume credentials.
3. Check status with `docker compose ps <postgres_service>`.
4. If not running or unhealthy, start it with `docker compose up -d <postgres_service>`.
5. Wait until healthy: `docker compose exec <postgres_service> pg_isready -U <user> -d <db>`.
6. Apply migrations through the repo target, usually `make migrate`; do not hand-apply migration SQL unless explicitly debugging a failed migration.
7. Inspect DB through an available read-only Postgres/Docker MCP tool when present. If no DB MCP tool exists, use Docker exec:
   `docker compose exec -T <postgres_service> psql -U <user> -d <db> -c "<SQL>"`.

If Compose uses environment-variable placeholders, read the referenced `.env`/shell defaults before connecting. If credentials are still missing, ask the user instead of guessing.

## Migration Paths And Run Flow

- Discover migration paths and commands from `Makefile`, README, docs, and existing migration folders before editing.
- Prefer repository Make targets for creating and applying migrations. Do not run the raw migration command first when `make migrate` exists; the Make target usually supplies required `POSTGRES_*` env values.
- Treat raw `go run ... -migrations-path=...` commands as implementation detail or fallback debugging commands. If running one directly, copy the same env/config used by the Make target.
- Prefer the newer service layout when it exists:
  - migration SQL files: `internal/storage/postgres/migrations/*.sql`
  - `make migrate-create` should create files in `internal/storage/postgres/migrations`
  - `make migrate` should supply env/config and invoke `cmd/migrations/main.go` with `file://./internal/storage/postgres/migrations`
- Use the legacy layout only for repositories that already have it:
  - migration SQL files: `cmd/migrations/migrations/*.sql`
  - `make migrate-create` should create files in `cmd/migrations/migrations`
  - `make migrate` should supply env/config and dispatch `cmd/main.go migrations` with `file://./cmd/migrations/migrations`
- For a brand new repository/service with no existing migrations, create the newer layout: `cmd/migrations/main.go` for the runner and `internal/storage/postgres/migrations` for SQL files.
- Common create target: `make migrate-create name=<snake_case_name>`
- Common apply target: `make migrate`

Common execution chain:

1. Ensure local Postgres is already running/reachable, usually through the repository Docker Compose service. A Makefile env assignment does not start Postgres unless the target explicitly runs Docker.
2. `make migrate` or equivalent repo target sets the `POSTGRES_*` env or reads Compose/config values.
3. New layout: `cmd/migrations/main.go` is invoked by the target; legacy layout: `cmd/main.go` dispatches the `migrations` command.
4. The migration command loads config, ensures the service DB exists, and runs `migrate.Up()`.

## Inspection Queries

- Migration state: `SELECT version, dirty FROM public.schema_migrations;`
- Schemas: `SELECT schema_name FROM information_schema.schemata ORDER BY schema_name;`
- Tables: `SELECT table_schema, table_name FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog', 'information_schema') AND table_type = 'BASE TABLE' ORDER BY table_schema, table_name;`
- Columns: `SELECT column_name, data_type, is_nullable, column_default FROM information_schema.columns WHERE table_schema = '<schema>' AND table_name = '<table>' ORDER BY ordinal_position;`
- Indexes: `SELECT indexname, indexdef FROM pg_indexes WHERE schemaname = '<schema>' AND tablename = '<table>';`
- Enums: `SELECT e.enumlabel FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid WHERE t.typname = '<enum>' ORDER BY e.enumsortorder;`

## Authoring Patterns

1. File naming: `<unix_timestamp>_<description>.up.sql`.
2. Prefer additive changes first:
   add nullable/default -> backfill -> enforce `NOT NULL`/constraints.
3. Guard drift-sensitive changes with `IF [NOT] EXISTS` and, when needed, `DO $$` + `information_schema` checks.
4. Backfills use targeted `UPDATE ... WHERE ...` with safety predicates (null/empty/regex guards).
5. Indexes: `CREATE INDEX IF NOT EXISTS`, naming usually ends with `_idx`.
6. Enum evolution uses `CREATE TYPE` / `ALTER TYPE ... ADD VALUE` / `RENAME VALUE`.
7. Seed-like inserts may use fixed UUIDs; prefer idempotency (`ON CONFLICT DO NOTHING`) when rerun risk exists.
8. Keep statements semicolon-terminated.

## Minimal Templates

Add + backfill + enforce:

```sql
ALTER TABLE <schema>.example ADD COLUMN IF NOT EXISTS new_col TEXT;

UPDATE <schema>.example
SET new_col = 'value'
WHERE new_col IS NULL;

ALTER TABLE <schema>.example
ALTER COLUMN new_col SET NOT NULL;
```

Guarded repair:

```sql
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = '<schema>' AND table_name = 'example' AND column_name = 'old_col'
  ) THEN
    ALTER TABLE <schema>.example RENAME COLUMN old_col TO new_col;
  END IF;
END $$;
```

## Verification Checklist

- apply locally through the repository migration target, such as `make migrate`
- re-run the same migration target and ensure idempotent result (`no change`/successful rerun)
- verify `schema_migrations` (`dirty=false`)
- run targeted tests for affected storage/module paths

## Common Mistakes

- editing historical migration already used in shared environments
- destructive `DROP TABLE` in `up` without explicit migration intent
- adding non-null columns without backfill strategy
- skipping guard conditions for drift-prone repairs
- forgetting that migration execution is environment-driven via `POSTGRES_*`

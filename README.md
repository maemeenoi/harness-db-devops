# harness-db-devops

Monorepo for Harness Database DevOps demos with **Liquibase** and **Flyway**, covering both **SQL Server** and **PostgreSQL**.

## Directory Structure

### Flyway Migrations

- `flyway/sql/` — Flyway migrations for SQL Server
- `flyway/pg/` — Flyway migrations for PostgreSQL

Each engine has scenario-based migration files:

- `schema/` — Schema and table creation (baseline setup)
- `data-seed/` — Data seeding operations
- `view/` — Create or modify views
- `function/` — User-defined functions
- `proc/` — Stored procedures
- `drop-column/` — Column removal operations
- `modify-objects/` — Object modifications (schema comments, view updates, function changes)
- `failure/` — Intentional failure scenarios for error handling testing

### Liquibase Changelogs

- `liquibase/sql/` — Liquibase changelogs for SQL Server
- `liquibase/pg/` — Liquibase changelogs for PostgreSQL

Each engine has scenario-based changelog folders:

- `schema/` — Schema and table creation
- `data-seed/` — Data seeding operations
- `view/` — Create or modify views
- `function/` — User-defined functions
- `proc/` — Stored procedures
- `drop-column/` — Column removal operations
- `modify-objects/` — Object modifications (schema comments, view updates, function changes)
- `failure/` — Intentional failure scenarios for error handling testing

Each scenario folder contains a `changelog.xml` (Liquibase) or `Vx__migration.sql` (Flyway).

---

## Evidence Documentation

- `evidenceCheckFlyway.md` — PostgreSQL Flyway migration evidence scripts
- `evidenceCheckLiquiPg.md` — PostgreSQL Liquibase migration evidence scripts
- `evidenceCheckLiquiSql.md` — SQL Server Liquibase migration evidence scripts

These files contain SQL queries to validate that migrations executed correctly, including schema objects, data consistency, and changelog entries.

---

## Database Changelog Tracking

- **Liquibase** tracks state in the `databasechangelog` table
- **Flyway** tracks state in the `flyway_schema_history` table

Both provide full audit history of applied migrations.

---

## Usage

### Liquibase

**SQL Server:**

```bash
# Run schema creation
liquibase update --changelog-file=liquibase/sql/schema/changelog.xml

# Run data seeding
liquibase update --changelog-file=liquibase/sql/data-seed/changelog.xml

# Run all scenarios in sequence
liquibase update --changelog-file=liquibase/sql/schema/changelog.xml
liquibase update --changelog-file=liquibase/sql/data-seed/changelog.xml
liquibase update --changelog-file=liquibase/sql/view/changelog.xml
liquibase update --changelog-file=liquibase/sql/function/changelog.xml
liquibase update --changelog-file=liquibase/sql/proc/changelog.xml
liquibase update --changelog-file=liquibase/sql/drop-column/changelog.xml
liquibase update --changelog-file=liquibase/sql/modify-objects/changelog.xml
liquibase update --changelog-file=liquibase/sql/failure/changelog.xml
```

**PostgreSQL:**

```bash
# Point to PostgreSQL changelogs
liquibase update --changelog-file=liquibase/pg/<scenario>/changelog.xml
```

---

### Flyway

**SQL Server:**

```bash
# Run schema creation
flyway migrate -locations=filesystem:flyway/sql/schema

# Run other scenarios
flyway migrate -locations=filesystem:flyway/sql/data-seed
flyway migrate -locations=filesystem:flyway/sql/view
```

**PostgreSQL:**

```bash
# Run schema creation
flyway migrate -locations=filesystem:flyway/pg/schema

# Run other scenarios
flyway migrate -locations=filesystem:flyway/pg/data-seed
flyway migrate -locations=filesystem:flyway/pg/view
```

---

## Key Features

### Scenario Parity

- Same test cases across Liquibase and Flyway for **apples-to-apples comparison**
- Includes schema, data, views, stored procs, functions, drop-column, modify-objects, and failure cases

### SQL Server Conversions

- T-SQL syntax (`INT`, `BIGINT`, `DATETIMEOFFSET`)
- Functions like `DATEADD`, `SYSDATETIMEOFFSET`
- Conditional `IF EXISTS` checks
- Extended properties for schema metadata

### PostgreSQL Coverage

- `plpgsql` functions
- `COMMENT ON SCHEMA` for schema metadata
- Proper interval handling for time-based logic

### Error Handling

- `failure/` scenarios designed to trigger controlled errors
- Liquibase uses `onFail="MARK_RAN"` for recovery
- Flyway stops migration until fixed

### Evidence Validation

Each migration type includes evidence scripts to confirm:

- Schema and table creation
- Data seeding and consistency
- Function/proc logic
- Changelog history updates
- Error capture and rollback safety

---

## Notes

- Liquibase uses XML changelogs, Flyway uses raw SQL scripts
- Both SQL Server and PostgreSQL are fully covered
- All scenarios are modular and independently executable
- Evidence scripts provide confidence in migration outcomes
- The structure allows Harness pipelines to trigger by scenario folders for CI/CD automation

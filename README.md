# harness-db-devops

Monorepo for Harness Database DevOps demos with **Liquibase** and **Flyway**, covering both **SQL Server** and **PostgreSQL**.

## Directory Structure

### Flyway Migrations

- `flyway/sql/` — Flyway migrations for SQL Server
- `flyway/pg/` — Flyway migrations for PostgreSQL

Each engine has versioned migration files following Flyway's `V{version}__{description}.sql` naming convention:

- `V1__create_schema.sql` — Schema creation
- `V2__create_feedbackaudit_table.sql` — Table creation with identity columns
- `V3__seed_feedbackaudit.sql` — Data seeding operations
- `V4__create_feedbackaudit_view.sql` — View creation
- `V5__create_count_recent_audits_function.sql` — User-defined functions
- `V6__add_source_column.sql` — Column addition
- `V7__drop_note_column.sql` — Column removal with dependency handling
- `V8__modify_schema_comment.sql` — Schema metadata updates
- `V9__modify_feedbackaudit_view.sql` — View modifications
- `V10__modify_count_recent_audits_function.sql` — Function updates
- `V11__create_get_recent_audits_proc.sql` — Stored procedures/functions
- `V12__failure_test_invalid_sql.sql` — Intentional failure for error handling testing

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

Each Liquibase scenario folder contains a `changelog.xml` file, while Flyway uses numbered migration files (`V1__description.sql`, `V2__description.sql`, etc.).

---

## Evidence Documentation

- `evidenceCheckFlyway.md` — **SQL Server** Flyway migration evidence scripts
- `evidenceCheckFlywayPg.md` — **PostgreSQL** Flyway migration evidence scripts
- `evidenceCheckLiquiPg.md` — PostgreSQL Liquibase migration evidence scripts
- `evidenceCheckLiquiSql.md` — SQL Server Liquibase migration evidence scripts

These files contain comprehensive SQL queries to validate that migrations executed correctly, including:

- Schema and table structure validation
- Data seeding verification
- Function and procedure testing
- View creation and modification checks
- Column addition/removal validation
- Migration history tracking
- Error handling verification

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
# Run all migrations in sequence (V1 through V12)
flyway migrate -locations=filesystem:flyway/sql

# Run up to a specific version
flyway migrate -target=V5 -locations=filesystem:flyway/sql

# Get migration status
flyway info -locations=filesystem:flyway/sql
```

**PostgreSQL:**

```bash
# Run all migrations in sequence (V1 through V12)
flyway migrate -locations=filesystem:flyway/pg

# Run up to a specific version
flyway migrate -target=V5 -locations=filesystem:flyway/pg

# Get migration status
flyway info -locations=filesystem:flyway/pg

# Clean database (development only)
flyway clean -locations=filesystem:flyway/pg
```

---

## Key Features

### Migration Tool Comparison

- **Liquibase**: Uses XML-based changelogs with scenario-based folders
- **Flyway**: Uses numbered SQL migration files (V1, V2, V3...)
- Same test cases across both tools for **apples-to-apples comparison**
- Covers schema creation, data seeding, views, functions, procedures, column operations, and error handling

### SQL Server Conversions

- T-SQL syntax (`INT`, `BIGINT`, `DATETIMEOFFSET`)
- Functions like `DATEADD`, `SYSDATETIMEOFFSET`
- Conditional `IF EXISTS` checks
- Extended properties for schema metadata

### PostgreSQL Features

- `plpgsql` and SQL functions with proper return types
- `GENERATED BY DEFAULT AS IDENTITY` for auto-increment columns
- `COMMENT ON SCHEMA` for schema metadata
- Interval arithmetic for date/time calculations (`'30 days'::interval`)
- Dependency handling for view/table relationships

### Error Handling & Dependency Management

- **Liquibase**: `failure/` scenarios with `onFail="MARK_RAN"` for recovery strategies
- **Flyway**: `V12__failure_test_invalid_sql.sql` with intentional syntax errors
- **PostgreSQL**: Proper dependency handling for view/table relationships (V7 drop column)
- **SQL Server**: Conditional object creation with `IF EXISTS` checks
- Both tools stop on errors and provide rollback capabilities

### Evidence Validation

Each migration type includes evidence scripts to confirm:

- Schema and table creation
- Data seeding and consistency
- Function/proc logic
- Changelog history updates
- Error capture and rollback safety

---

## Migration Execution Notes

### Flyway Versioning

- Migrations execute in numerical order (V1 → V2 → V3...)
- Each migration runs exactly once per database
- Use `flyway info` to check migration status
- Failed migrations must be fixed before proceeding

### Liquibase Scenarios

- Each scenario folder is independent
- Can be executed in any order or combination
- Use changesets with proper preconditions
- Supports rollback operations

### Database-Specific Considerations

**PostgreSQL:**

- V7 requires careful dependency management (view drop before column drop)
- Uses `IF NOT EXISTS` for safe re-runs
- Functions return specific types (set-returning functions for procedures)

**SQL Server:**

- Conditional object creation with `IF EXISTS` patterns
- Uses `IDENTITY(1,1)` for auto-increment
- Extended properties for metadata storage

### CI/CD Integration

- Evidence scripts validate migration success
- Each tool provides migration history tracking
- Structure supports automated pipeline triggers
- Both tools integrate with Harness and other DevOps platforms

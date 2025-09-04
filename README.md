# harness-db-devops

Monorepo for Harness database DevOps demos

## Directory Structure

### Flyway Migrations

- `flyway/pg/` — Flyway migrations for PostgreSQL
- `flyway/sql/` — Flyway migrations for SQL Server

Each engine has scenario-based migration files:

- `baseline/` — `V1__baseline.sql` (initial schema setup)
- `schema/` — `V2__schema.sql` (schema changes)
- `proc/` — `V3__proc.sql` (stored procedures)
- `failure/` — `V4__failure.sql` (failure scenarios)

### Liquibase Changelogs

- `liquibase/pg/` — Liquibase changelogs for PostgreSQL
- `liquibase/sql/` — Liquibase changelogs for SQL Server

Each engine has scenario-based changelog folders:

- `schema/` — Schema and table creation
- `data-seed/` — Data seeding operations
- `view/` — View creation and modifications
- `function/` — User-defined functions
- `proc/` — Stored procedures
- `drop-column/` — Column removal operations
- `modify-objects/` — Object modifications (schema comments, view updates, function changes)
- `failure/` — Intentional failure scenarios for error handling testing

Each scenario folder contains a `changelog.xml` file with database-specific SQL.

## Evidence Documentation

- `evidenceCheckFlyway.md` — PostgreSQL Flyway migration evidence scripts
- `evidenceCheckLiqiPg.md` — PostgreSQL Liquibase migration evidence scripts
- `evidenceCheckLiquiSql.md` — SQL Server Liquibase migration evidence scripts

These files contain comprehensive SQL queries to verify successful migrations and test database functionality.

## Database Changelog Tracking

- `databasechangelog.csv` — Sample Liquibase changelog data

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

### Flyway

**SQL Server:**

```bash
# Point Flyway CLI to SQL Server scenario folder
flyway migrate -locations=filesystem:flyway/sql/<scenario>/
```

**PostgreSQL:**

```bash
# Point Flyway CLI to PostgreSQL scenario folder
flyway migrate -locations=filesystem:flyway/pg/<scenario>/
```

## Key Features

### SQL Server Conversions

All SQL Server Liquibase changelogs have been converted from PostgreSQL syntax to use:

- T-SQL syntax and data types (`INT`, `BIGINT`, `DATETIMEOFFSET`)
- SQL Server functions (`DATEADD`, `SYSDATETIMEOFFSET`)
- SQL Server object management (conditional `DROP`/`CREATE` patterns)
- Extended properties for schema metadata

### Error Handling

The `failure/` scenarios test Liquibase error handling with:

- `failOnError="true"` settings
- `onFail="MARK_RAN"` recovery strategies
- Duplicate object creation attempts

### Evidence Validation

Each migration type includes comprehensive evidence scripts to verify:

- Object creation and structure
- Data integrity and consistency
- Functional testing of database objects
- Liquibase changelog tracking
- Error recovery and system stability

## Notes

- All Liquibase SQL Server changelogs use proper T-SQL syntax
- Each scenario is self-contained and can be run independently
- Evidence scripts provide comprehensive validation of migration success
- The repository demonstrates both successful migrations and failure handling
- Folder structure enables easy comparison between Liquibase and Flyway approaches

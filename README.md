# harness-db-devops

Monorepo for Harness database DevOps demos

## Directory Structure

- `db/liquibase/pg/` and `db/liquibase/sql/` — Liquibase changelogs for PostgreSQL and SQL Server

  - Each engine has subfolders for scenarios:
    - `baseline/` — initial schema
    - `schema/` — schema changes
    - `proc/` — stored procedures
    - `failure/` — failure scenarios
  - Each scenario contains a `changelog.xml` file

- `db/flyway/pg/` and `db/flyway/sql/` — Flyway migrations for PostgreSQL and SQL Server

  - Each engine has subfolders for scenarios:
    - `baseline/` — `V1__baseline.sql`
    - `schema/` — `V2__schema.sql`
    - `proc/` — `V3__proc.sql`
    - `failure/` — `V4__failure.sql`

- `db/sql/` — Shared SQL scripts
  - `postgres/` and `sqlserver/` subfolders mirror the scenario structure above
    - Useful for reference or direct execution

## Usage

### Liquibase

- Baseline changelogs:
  - SQL Server: `db/liquibase/sql/baseline/changelog.xml`
  - PostgreSQL: `db/liquibase/pg/baseline/changelog.xml`
- For other scenarios, use the corresponding changelog in each scenario folder.

### Flyway

- Point Flyway CLI to the appropriate engine and scenario folder:
  - PostgreSQL: `db/flyway/pg/<scenario>/`
  - SQL Server: `db/flyway/sql/<scenario>/`
- Migrations follow the `V*__description.sql` naming convention.

## Notes

- Shared SQL scripts in `db/sql/` can be used independently or as templates for migrations.
- The folder structure is designed for easy comparison between Liquibase and Flyway approaches across engines and scenarios.

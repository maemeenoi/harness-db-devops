# harness-db-devops

Monorepo for Harness database DevOps demos:

- `db/liquibase/sql/...` and `db/liquibase/pg/...` → Liquibase changelogs per engine & scenario
- `db/flyway/...` → Flyway V\* migrations
- `db/sql/...` → shared SQL (if used by either tool)

## Liquibase

- Baseline changelogs:
  - SQL Server: `db/liquibase/sql/baseline/changelog.xml`
  - PostgreSQL: `db/liquibase/pg/baseline/changelog.xml`

## Flyway

- Point Flyway CLI to `db/flyway/<engine>/...` as needed.

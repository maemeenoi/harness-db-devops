# PostgreSQL Evidence Checks – Liquibase Tests (northwind.redgate)

```sql
-- ==========================================
-- Context
-- ==========================================
SELECT current_database() AS db, current_user AS usr;

-- ==========================================
-- 1. Schema + Table (schema/changelog.xml)
-- ==========================================
-- Schema exists
SELECT nspname FROM pg_namespace WHERE nspname='redgate';

-- Table exists + columns
SELECT to_regclass('redgate.feedback_audit') AS table_oid;
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema='redgate' AND table_name='feedback_audit'
ORDER BY ordinal_position;

-- Row count
SELECT COUNT(*) AS feedback_audit_rows FROM redgate.feedback_audit;

-- Changelog entries
SELECT id, filename, dateexecuted
FROM databasechangelog
WHERE filename LIKE '%/liquibase/pg/schema/%'
ORDER BY dateexecuted DESC;

-- ==========================================
-- 2. Seed (data-seed/changelog.xml)
-- ==========================================
-- Row count after seed
SELECT COUNT(*) AS rowcount_after_seed FROM redgate.feedback_audit;

-- Sample rows
SELECT * FROM redgate.feedback_audit ORDER BY audit_id DESC LIMIT 5;

-- Changelog entries
SELECT id, filename, dateexecuted
FROM databasechangelog
WHERE filename LIKE '%/liquibase/pg/data-seed/%'
ORDER BY dateexecuted DESC;

-- ==========================================
-- 3. View (schema-rg/changelog.xml)
-- ==========================================
-- View exists
SELECT to_regclass('redgate.feedback_audit_summary') AS view_oid;

-- View columns
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema='redgate' AND table_name='feedback_audit_summary'
ORDER BY ordinal_position;

-- View data (if any)
SELECT * FROM redgate.feedback_audit_summary LIMIT 5;

-- Changelog entries
SELECT id, filename, dateexecuted
FROM databasechangelog
WHERE filename LIKE '%/liquibase/pg/schema-rg/%'
ORDER BY dateexecuted DESC;

-- ==========================================
-- 4. Function (function/changelog.xml)
-- ==========================================
-- Function exists
SELECT p.proname, pg_get_function_identity_arguments(p.oid) AS args
FROM pg_proc p
JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='redgate' AND p.proname='count_recent_audits';

-- Function call
SELECT redgate.count_recent_audits(30) AS recent_30d;

-- Changelog entries
SELECT id, filename, dateexecuted
FROM databasechangelog
WHERE filename LIKE '%/liquibase/pg/function/%'
ORDER BY dateexecuted DESC;

-- ==========================================
-- 5. Drop column (drop-column/changelog.xml)
-- ==========================================
-- Column list (note should be gone)
SELECT column_name
FROM information_schema.columns
WHERE table_schema='redgate' AND table_name='feedback_audit'
ORDER BY ordinal_position;

-- Row count unchanged
SELECT COUNT(*) AS rows_after_drop FROM redgate.feedback_audit;

-- View still valid
SELECT * FROM redgate.feedback_audit_summary LIMIT 1;

-- Changelog entries
SELECT id, filename, dateexecuted
FROM databasechangelog
WHERE filename LIKE '%/liquibase/pg/drop-column/%'
ORDER BY dateexecuted DESC;

-- ==========================================
-- 6. Modify objects (modify-objects/changelog.xml)
-- ==========================================
-- Schema comment
SELECT obj_description(n.oid,'pg_namespace') AS schema_comment
FROM pg_namespace n WHERE n.nspname='redgate';

-- View definition changed
SELECT column_name
FROM information_schema.columns
WHERE table_schema='redgate' AND table_name='feedback_audit_summary'
ORDER BY ordinal_position;

-- Function definition updated
SELECT pg_get_functiondef(p.oid)
FROM pg_proc p
JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='redgate' AND p.proname='count_recent_audits'
LIMIT 1;

-- Changelog entries
SELECT id, filename, dateexecuted
FROM databasechangelog
WHERE filename LIKE '%/liquibase/pg/modify-objects/%'
ORDER BY dateexecuted DESC;

-- ==========================================
-- 7. Failure scenario (failure/changelog.xml)
-- ==========================================
-- Expect no success entry (prove it failed)
SELECT id, filename, dateexecuted
FROM databasechangelog
WHERE filename LIKE '%/liquibase/pg/failure/%'
ORDER BY dateexecuted DESC;
```

---

📸 Suggested evidence capture:

- For each block, screenshot both the **Harness step log** and the **query results** grid.
- Keep them in a folder per test (e.g. `/docs/evidence/pg/schema`, `/pg/seed` …).

Do you also want me to build the **SQL Server version** of this evidence script so you have identical structure across both databases?
